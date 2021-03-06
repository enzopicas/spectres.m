% Cette fonction transforme un spectre au format texte en signal audio.
% -----Prototype de la fonction------
% [audio] = transposition(spectre_nm, T, methode, fe)
%
% audio = signal de sortie
% spectre_nm = nom du tableau avec les informations du spectre
% T = durée (s) pendant laquelle le signal de sortie sera joué
% fe = fréquence d'échentillonage (Hz) valeur par défaut 44100 Hz
% methode = choix de la méthode de transposition
%   1 : Pseudo mélodie avec transposition linéaire
%   2 : Un seul son avec transposition linéaire
%   3 : Un seul son avec f1 = L1 ; f2 = 3/2L1 ; f3 = L3/L2 f2 ...
%   4 : Mélodie, calculée à partir d'une transposition linéaire

function [audio] = transposition(spectre_nm, T, methode, fe)
    
    %--------------------------
    % TRANSPOSITION
    %--------------------------
    Fmin = 125; Fmax = 4000; % Gamme de fréquences
    Fref = 261.626;
    Lmin = 300; Lmax = 800; % Longueurs d'onde dans le domaine visible
    
    spectre_OptHz = sort(1./spectre_nm(:,1));
    
    if nargin < 3
        methode = 4;
    end
    
    if methode == 1 || methode == 2 % Transposition linéaire
        a=(Fmax-Fmin)/(1/Lmin-1/Lmax);
        b=Fmin-a*(1/Lmax);
        spectre_Hz = (1./spectre_nm(:,1)) * a + b;
        spectre_Hz = sort(spectre_Hz);
    
    elseif methode == 3 % Transposition avec f2 tierce
        spectre_Hz(1) = Fref;
        spectre_Hz(2) = (3/2) * spectre_Hz(1);
        for i = 3:length(spectre_OptHz)
            spectre_Hz(i) = (spectre_OptHz(i)/spectre_OptHz(i-1)) * spectre_Hz(i-1);
        end
    end
    
    %--------------------------
    % SIGNAL AUDIO
    %--------------------------
    if nargin < 4
        fe = 44100;
    end
    
    if methode == 1 % Pseudo mélodie
        t = 0:1/fe:T/length(spectre_Hz);
        audio = [];
        for i = 1:length(spectre_Hz)
            audio = [audio sin(2*pi*spectre_Hz(i)*t)];
        end
        
    elseif methode == 2 || methode == 3 % Un seul son
        t = 0:1/fe:T;
        audio = zeros(size(t));
        for i = 1:length(spectre_Hz)
            audio = audio + spectre_nm(i,2)*sin(2*pi*spectre_Hz(i)*t);
        end;
    end
    
      %--------------------------
      % METHODE 4 : MELODIE
      %--------------------------
      if methode == 4
          % Transposition linéaire
          a=(Fmax-Fmin)/(1/Lmin-1/Lmax);
          b=Fmin-a*(1/Lmax);
          spectre_Hz = (1./spectre_nm(:,1)) * a + b;
          
          % Signal audio
          nbMax = length(0:1/fe:T);
          Amax = max(spectre_nm(:,2));
          audio = zeros(1,nbMax);
          
          for i = 1:size(spectre_Hz)
             audio_temp = [];
             t = 0:1/fe:spectre_nm(i,2)/Amax;
             n = 0;
             
             while length(audio_temp) < nbMax
                if mod(n,2) == 0 % n pair
                  audio_temp = [audio_temp spectre_nm(i,2)*sin(2*pi*spectre_Hz(i)*t)];
                  n = n + 1;
                else % n impair
                  audio_temp = [audio_temp zeros(1,length(t))];
                  n = n + 1;
                end
             end
             
             audio_temp = audio_temp(1:nbMax);
             audio = audio + audio_temp;
          end
          
      end
    
    audio = audio/max(audio);
    
    if methode ~= 1
        figure;
        plot(0:1/fe:T,audio); title('Signal audio en temporel');
    end
    
    %--------------------------
    % FFT
    %--------------------------
    L = length(audio);
    Y = fft(audio);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fe*(0:(L/2))/L;
    
    figure;
    plot(f,P1)
    title('FFT du signal audio');
    xlabel('Frequences (Hz)'); xlim([0, 4000]);
    
end
