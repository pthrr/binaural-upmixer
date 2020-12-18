% --------------------------------------------------------------------
%
% Implementation of a STFT according to "On the Development of
% STFT-analysis and ISTFT-synthesis Routines and their Practical
% Implementation" - Zhivomirov (2019)
% x: array repesenting the time domain signal
% nfft: size of fft
% returns: array representing the time domain signal in frequency domain
%
% --------------------------------------------------------------------

function [X] = stft(x, nfft)
  n = length(x);
  hop = nfft/4; % maximum value for WOLA of hamming window is nfft/3
  w = hamming(nfft, 'periodic');

  % find dimensions
  freqs = nfft/2 + 1; % two-sided + nyquist point
  bloecke = floor((n-nfft)/hop) + 1;
  X = zeros(freqs, bloecke);

  % do calculation
  for idx = 0:hop:(n-nfft)
    block = idx/hop + 1;

    % window time domain signal
    x_win = x(idx+1:idx+nfft) .* w;

    % calculate fft
    X(:, block) = fft(x_win, nfft)(1:freqs);
  end
end