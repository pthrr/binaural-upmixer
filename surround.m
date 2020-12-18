% --------------------------------------------------------------------
%
% This function colvolves 5.1 audio signals with Binaural Room Impulse
% Responses (BRIR) and upmixes the input if necessary
% x: input signal, either true surround or stereo
% mmode: enable music mode
% fs: sampling frequency of the input
% returns: binaural encoded stereo signal retrieved either from true surround
%          or stereo compensated for frequency response of headphones
%
% --------------------------------------------------------------------

function y = surround(x, mmode, fs)
  % check inputs
  if (nargin ~= 3 || (size(x, 2) ~= 2 && size(x, 2) ~= 6))
    disp('Number or dimensions of inputs are not compatible!');
    return;
  end

  if (fs ~= 44100)
    disp('The sampling rate has to match 44.1 kHz!');
    return;
  end

  % if surround, split channel
  if (size(x, 2) == 6)
    l = x(:, 1);
    c = x(:, 2);
    r = x(:, 3);
    lr = x(:, 4);
    rr = x(:, 5);
    b = x(:, 6);
  end
  
  % if stereo, upmix to surround
  if (size(x, 2) == 2)
    [l, c, r, lr, rr, b] = upmix(x, fs);
  end

  % use BRIRs as tranfer functions
  n30l = audioread('brir_neg030_l.wav');
  n30r = audioread('brir_neg030_r.wav');

  p00l = audioread('brir_pos000_l.wav');
  p00r = audioread('brir_pos000_r.wav');

  p30l = audioread('brir_pos030_l.wav');
  p30r = audioread('brir_pos030_r.wav');

  n11l = audioread('brir_neg110_l.wav');
  n11r = audioread('brir_neg110_r.wav');

  p11l = audioread('brir_pos110_l.wav');
  p11r = audioread('brir_pos110_r.wav');

  % process left BRIRs
  x1l = conv(l, n30l);
  x2l = conv(c, p00l);
  x3l = conv(r, p30l);
  x4l = conv(lr, n11l);
  x5l = conv(rr, p11l);
  x6l = 0.707 * b; % bass frequencies are not localizable

  % process right BRIRs
  x1r = conv(l, n30r);
  x2r = conv(c, p00r);
  x3r = conv(r, p30r);
  x4r = conv(lr, n11r);
  x5r = conv(rr, p11r);
  x6r = 0.707 * b; % bass frequencies are not localizable

  % simulate Haas effect by delaying the rear speaker signals
  if (mmode ~= 1 && size(x, 2) ~= 6) % only if not in music mode and not true surround
    delay = round(0.020 * fs); % by 20 ms
    x4l = [zeros(delay, 1)' x4l']';
    x4r = [zeros(delay, 1)' x4r']';
    x5l = [zeros(delay, 1)' x5l']';
    x5r = [zeros(delay, 1)' x5r']';
  end

  % downmix to stereo
  lengths = [length(x1l) length(x2l) length(x3l) length(x4l) length(x5l) length(x6l) ...
             length(x1r) length(x2r) length(x3r) length(x4r) length(x5r) length(x6r)];

  max_length = max(lengths);
  [yl, yr] = deal(zeros(max_length, 1));

  % left
  yl(1:lengths(1)) = yl(1:lengths(1)) + x1l; % l
  yl(1:lengths(2)) = yl(1:lengths(2)) + x2l; % c
  yl(1:lengths(3)) = yl(1:lengths(3)) + x3l; % r
  yl(1:lengths(4)) = yl(1:lengths(4)) + x4l; % lr
  yl(1:lengths(5)) = yl(1:lengths(5)) + x5l; % rr
  yl(1:lengths(6)) = yl(1:lengths(6)) + x6l; % b

  % right
  yr(1:lengths(7)) = yr(1:lengths(7)) + x1r; % l
  yr(1:lengths(8)) = yr(1:lengths(8)) + x2r; % c
  yr(1:lengths(9)) = yr(1:lengths(9)) + x3r; % r
  yr(1:lengths(10)) = yr(1:lengths(10)) + x4r; % lr
  yr(1:lengths(11)) = yr(1:lengths(11)) + x5r; % rr
  yr(1:lengths(12)) = yr(1:lengths(12)) + x6r; % b

  % compensate for frequency response of headphones
  hc = audioread('hd25_hcomp.wav');
  yl = conv(yl, hc);
  yr = conv(yr, hc);

  % normalize
  ymax = max(max([yl yr]));

  if (ymax > 1.0) % 1.0 is 0 dBfs
     yl = yl / sqrt(sum(yl.^2)/length(yl)); % normalize/compress to rms value
     yr = yr / sqrt(sum(yr.^2)/length(yr)); % normalize/compress to rms value
  end

  y = [yl yr];
end