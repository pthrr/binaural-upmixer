% --------------------------------------------------------------------
%
% Implementation of "Stereo signal separation and upmixing by
% mid-side decomposition in the frequency-domain" - Kraft, Zölzer (2015)
% x: matrix repesenting a stereo signal
% fs: sampling frequency of the stereo signal
% returns: array of 5+1 separate signals representing the upmixed stereo
%
% --------------------------------------------------------------------

function [l, c, r, lr, rr, b] = upmix(x, fs)
  % split stereo
  xl = x(:, 1); % left
  xr = x(:, 2); % right

  % stft
  nfft = 2048; % fft length
  Xl = stft(xl, nfft);
  Xr = stft(xr, nfft);

  % find dimensions
  bloecke = min([size(Xl, 2) size(Xr, 2)]);
  freqs = min([size(Xl, 1) size(Xr, 1)]);

  % calculate weights for mid-side in frequency domain
  al = zeros(freqs, bloecke);
  ar = zeros(freqs, bloecke);
  alm = zeros(1, bloecke); % middle weights
  arm = zeros(1, bloecke); % middle weights

  for b = 1:bloecke
    for k = 1:freqs
      al(k,b) = abs(Xl(k,b)) / (sqrt(abs(Xl(k,b))^2 + abs(Xr(k,b))^2));
      ar(k,b) = abs(Xr(k,b)) / (sqrt(abs(Xl(k,b))^2 + abs(Xr(k,b))^2));
      alm(b) = alm(b) + (al(k,b) / freqs);
      arm(b) = arm(b) + (ar(k,b) / freqs);
    end
  end

  % split spectrum according to weights
  D = zeros(freqs, bloecke);
  Nl = zeros(freqs, bloecke);
  Nr = zeros(freqs, bloecke);
  
  for b = 1:bloecke
    for k = 1:freqs
      D(k,b) = (Xl(k,b) * (-0.309017+1i*0.951057) - Xr(k,b)) / ...
               (al(k,b) * (-0.309017+1i*0.951057) - ar(k,b));
      Nl(k,b) = Xl(k,b) - al(k,b) * D(k,b);
      Nr(k,b) = Xr(k,b) - ar(k,b) * D(k,b);
    end
  end

  % istft
  d = istft(D, nfft); % direct component
  nl = istft(Nl, nfft); % diffuse component left
  nr = istft(Nr, nfft); % diffuse component right

  %audiowrite('0_Direktschall.wav', d, fs);
  %audiowrite('1_Diffusschall.wav', [nl nr], fs);

  % subwoofer crossover for direct component creating sub bass
  [b, a] = cheby1(6, 0.5, 300/(fs/2), 'low');
  sub = filter(b, a, d);

  [b, a] = cheby1(6, 0.5, 300/(fs/2), 'high');
  d = filter(b, a, d);

  % low pass diffuse components to simulate losses by reflection
  sos = iirparameq(2, -10, 1, 10000/(fs/2));
  nl = sosfilt(sos, nl);
  nr = sosfilt(sos, nr);

  % calculate gain coefficients for 2D setup
  laenge = min([length(d) length(nl) length(nr)]);
  alaenge = min([length(alm) length(arm)]);

  gb = 0.8; % gain for sub bass signal
  gn = 1.0; % gain for diffuse components
  [gl, gc, gr] = deal(zeros(laenge, 1));

  for n = 1:laenge
    b = map(laenge, alaenge, n);
    gl(n) = alm(b);
    gr(n) = arm(b);
    gc(n) = 0.5 * (alm(b) + arm(b)); % pan signal to the center of left and right
  end

  % smooth out gain coefficients
  [b, a] = butter(6, 1000/(fs/2), 'low');
  gl = filter(b, a, gl);
  gr = filter(b, a, gr);
  gc = filter(b, a, gc);

  % downmix to 5.1
  [l, c, r, lr, rr, b] = deal(zeros(laenge, 1));

  for n = 1:laenge
    l(n) = gn * nl(n) + gl(n) * d(n);
    c(n) = gc(n) * d(n);
    r(n) = gn * nr(n) + gr(n) * d(n);
    lr(n) = gn * nl(n);
    rr(n) = gn * nr(n);
    b(n) = gb * sub(n);
  end
end