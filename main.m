% --------------------------------------------------------------------
%
% Implementation of a binaural stereo to surround upmixer partially based on
% "Stereo signal separation and upmixing by mid-side decomposition in the
% frequency-domain" - Kraft, Zölzer (2015)
%
% --------------------------------------------------------------------

close all;
%clear all;
clc;

qmode = 1; % stereo mode (1/0)
mmode = 1; % music mode (1/0)
sec = 10; % length of processing in seconds

%% use stereo source
if (qmode == 1)
  filename = './Hermelin/Hermelin-stereo';
  %filename = './Nighty_Night/Nighty_Night-stereo';
  %filename = './Open_Goldberg_Variatio_18a1/Open_Goldberg_Variatio_18a1-stereo';
  %filename = './Street_Atmo/Street_Atmo-stereo_44_1';
  %filename = './Sinus/sinus';
  %filename = './Sinus/sinus_pan';
  %filename = './Ing_Bast/ingbast';
  [x, fs] = audioread(strcat(filename, '.wav'));

  y = surround(x(1:(sec * fs), :), mmode, fs);

  filename = strsplit(filename, '/');
  filename = filename(find(~cellfun('isempty', filename), 1, 'last'));
  audiowrite(strcat('2_', char(filename), '_surround.wav'), y, fs);
end

%% use surround source
if (qmode == 0)
  [l, fs] = audioread('./Surround_Test/l.wav');
  [c, fs] = audioread('./Surround_Test/c.wav');
  [r, fs] = audioread('./Surround_Test/r.wav');
  [lr, fs] = audioread('./Surround_Test/sl.wav');
  [rr, fs] = audioread('./Surround_Test/sr.wav');
  [b, fs] = audioread('./Surround_Test/lfe.wav');
  x = [l c r lr rr b];
  
  y = surround(x, mmode, fs);

  audiowrite('2_Surround_Test_surround.wav', y, fs);
end

disp('Done.');