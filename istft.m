% --------------------------------------------------------------------
%
% Implementation of a STFT according to "On the Development of
% STFT-analysis and ISTFT-synthesis Routines and their Practical
% Implementation" - Zhivomirov (2019)
% X: array representing the time domain signal in frequency domain
% nfft: size of fft
% returns: array repesenting the time domain signal
%
% --------------------------------------------------------------------

function [x] = istft(X, nfft)
  bloecke = size(X, 2);
  hop = nfft/4; % maximum value for WOLA of hamming window is nfft/3
  w = hamming(nfft, 'periodic');

  % find dimensions
  n = ((bloecke-1)*hop) + nfft; % per hop one block excluding one fft
  x = zeros(1, n);

  % do calculation
  for idx = 0:hop:(n-nfft)
    block = idx/hop + 1;
    Xf = X(:, block);

    % calculate ifft
    Xf = [Xf; conj(Xf(end-1:-1:2))]; % restore one-sided spectrum in reverse order
    xt = real(ifft(Xf));

    % WOLA
    x((idx+1):(idx+nfft)) = x((idx+1):(idx+nfft)) + (xt .* w)';
  end

  % scale according to eq. (6)
  e = sum(w .* w); % synthesis equals analysis window
  x = x .* (hop/e);
end