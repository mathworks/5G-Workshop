function pn_PSD = hPhaseNoisePoleZeroModel(f,fc,varargin)
%hPhaseNoisePoleZeroModel Phase noise characteristic with pole-zero model
%   PSD = hPhaseNoisePoleZeroModel(F,Fc,MODEL) generates the phase noise
%   characteristic PSD in dBc/Hz for the frequency offset values specified
%   by vector F for the carrier frequency Fc and phase noise parameters set
%   selected by MODEL. The units of F and Fc is Hz. MODEL must be one of
%   {'A', 'B', 'C'}. When the MODEL is set to 'A', the parameters used are
%   obtained from the response of a practical oscillator operated at 30 GHz,
%   as specified in R1-163984. Similarly, when MODEL is set to 'B', the
%   parameters used are obtained from the response of a practical
%   oscillator operated at 60 GHz, as specified in R1-163984. When MODEL is
%   set to 'C', the parameters used are obtained from the response of a
%   practical oscillator operated at 29.55 GHz, as specified in TR 38.803.
%
%   PSD = hPhaseNoisePoleZeroModel(F,Fc,FcBASE,Fz,Fp,ALPHAz,ALPHAp,PSD0)
%   generates the phase noise characteristic PSD in dBc/Hz for the
%   frequency offset values specified by vector F for the carrier frequency
%   Fc, reference base frequency of the oscillator FcBASE, zero frequencies
%   of the frequency response Fz, pole frequencies of the frequency
%   response Fp, order of zero frequencies ALPHAz, order of pole
%   frequencies ALPHAp, and the power spectral density of oscillator for
%   zero frequency PSD0. Fz, Fp, ALPHAz, and ALPHAp are vectors. Fc,
%   FcBase, and PSD0 are scalars. The units of F, Fc, FcBASE, Fz, and Fp is
%   Hz. Note that Fz and ALPHAz must have the same length. Similarly, Fp
%   and ALPHAp must have the same length.

% Copyright 2020 The MathWorks, Inc.

    narginchk(3,8);

    fcnName = 'hPhaseNoisePoleZeroModel';
    validateattributes(f,{'double'},{'real','finite','nonempty','vector'},fcnName,'F');
    validateattributes(fc,{'double'},{'real','finite','scalar','nonnegative'},fcnName,'Fc');
    if nargin == 3
        % Parse input
        model = varargin{1};
        model = validatestring(model,{'A','B','C'},fcnName,'MODEL');

        % Pole/zeros and PSD0
        switch model
            case 'A'
                % Parameter set A (R1-163984)
                fcBase = 30e9;
                fz = [1.8 2.2 40]*1e6;
                fp = [0.1 0.2 8]*1e6;
                alphaz = [2 2 2];
                alphap = [2 2 2];
                PSD0 = -79.4;
            case 'B'
                % Parameter set B (R1-163984)
                fcBase = 60e9;
                fz = [0.02 6 10]*1e6;
                fp = [0.005 0.4 0.6]*1e6;
                alphaz = [2 2 2];
                alphap = [2 2 2];
                PSD0 = -70;
            otherwise
                % Parameter set C (TR 38.803)
                fcBase = 29.55e9;
                fz = [3e3 550e3 280e6];
                fp = [1 1.6e6 30e6];
                alphaz = [2.37 2.7 2.53];
                alphap = [3.3 3.3 1];
                PSD0 = 32;
        end
    else
        narginchk(8,8);
        % Parse inputs
        fcBase = varargin{1};
        fz = varargin{2};
        fp = varargin{3};
        alphaz = varargin{4};
        alphap = varargin{5};
        PSD0 = varargin{6};
        % Validate the inputs
        validateattributes(fcBase,{'double'},{'real','finite','scalar','positive'},fcnName,'FcBASE');
        validateattributes(fz,{'double'},{'real','finite','nonempty','vector'},fcnName,'Fz');
        validateattributes(fp,{'double'},{'real','finite','nonempty','vector'},fcnName,'Fp');
        validateattributes(alphaz,{'double'},{'real','finite','nonempty','vector','nonnegative','numel',numel(fz)},fcnName,'ALPHAz');
        validateattributes(alphap,{'double'},{'real','finite','nonempty','vector','nonnegative','numel',numel(fp)},fcnName,'ALPHAp');
        validateattributes(PSD0,{'double'},{'real','finite','scalar'},fcnName,'PSD0');
    end

    % Compute numerator
    num = ones(size(f));
    for ii = 1:numel(fz)
        num = num.*(1 + (f./fz(ii)).^alphaz(ii));
    end

    % Compute denominator
    den = ones(size(f));
    for ii = 1:numel(fp)
        den = den.*(1 + (f./fp(ii)).^alphap(ii));
    end

    % Compute phase noise and apply a shift for carrier frequencies
    % different from the base frequency
    pn_PSD = 10*log10(num./den) + PSD0 + 20*log10(fc/fcBase);

end
