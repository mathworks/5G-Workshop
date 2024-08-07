function cw = PBCHdecode(sym,ncellid,v,nest,csi)   %pbchBits = nrPBCHDecode(pbchEq,ncellid,ssbIndex,nest);
%nrPBCHDecode Physical broadcast channel decoding    
%   CW = nrPBCHDecode(SYM,NCELLID,V) returns a vector of soft bits CW
%   resulting from performing the inverse of physical broadcast channel
%   (PBCH) processing as defined in TS 38.211 Section 7.3.3. SYM is the
%   received PBCH symbols consisting of 432 symbols, NCELLID is the
%   physical layer cell identity (0...1007), and V is the 2 or 3 LSBs
%   (0...7) of the SS/PBCH block index (used to select a portion of the
%   scrambling sequence).
%
%   For SS burst configurations with L as 4 SS/PBCH blocks per half frame,
%   V is the 2 LSBs of the SS/PBCH block index (0...3). For SS burst
%   configurations with L as 8 or 64 SS/PBCH blocks per half frame, V is 3
%   LSBs of the SS/PBCH block index (0...7).
%
%   CW = nrPBCHDecode(...,NVAR) allows specification of the noise
%   variance estimate NVAR employed for PBCH demodulation. When not
%   specified, it defaults to 1e-10.
%
%   Example:
%   % Generate the PBCH symbols (QPSK) for the first SS/PBCH block in a 
%   % burst (ssbindex is 0) from random bits representing encoded BCH bits.
%
%   ncellid = 17;
%   ssbindex = 0;
%   v = mod(ssbindex,4);    % assuming L as 4 SS/PBCH blocks per half frame
%   E = 864;                % PBCH bit capacity, TS 38.212 Section 7.1.5
%   cw = randi([0 1],E,1);
%
%   sym = nrPBCH(cw,ncellid,v);
%
%   % Demodulate the PBCH symbols to create bit estimates
%   rxcw = nrPBCHDecode(sym,ncellid,v);
%
%   isequal(cw, rxcw<0)
%
%   See also nrPBCH, nrPBCHIndices, nrPBCHPRBS, nrPBCHDMRS, nrPSS, nrSSS,
%   nrPRBS, nrPBCHDMRSIndices.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

    
nVar=nest;
    % Validate inputs
    fcnName = 'nrPBCHDecode';
    validateattributes(ncellid,{'numeric'}, ...
        {'scalar','integer','>=',0,'<=',1007},fcnName,'NCELLID');
    validateattributes(v,{'numeric'}, ...
        {'scalar','integer','>=',0,'<=',7},fcnName,'V');
    validateattributes(nVar, {'double','single'}, ...
    {'real','scalar','nonnegative','finite','nonnan'}, ...
    fcnName,'NVAR');
    validateattributes(sym,{'double','single'},{'column'},fcnName,'SYM');

    % Demodulation, Section 7.3.3.2, TS 38.211
    demod = nrSymbolDemodulate(sym,'QPSK',nVar);

    % Get scrambling sequence
    opts.MappingType = 'signed';
    opts.OutputDataType = class(sym);
    c = nrPBCHPRBS(ncellid,v,length(demod),opts);

    % Descrambling, Section 7.3.3.1, TS 38.211
    cw = demod .* c;




% Calculate RMS PBCH EVM
pbchRef = nrPBCH(cw<0,ncellid,v);
evm = comm.EVM;
pbchEVMrms = evm(pbchRef,sym);
% Plot received PBCH constellation after equalization
figure;
plot(sym,'o');
%scatter(real(pbchEq),imag(pbchEq))
xlabel('In-Phase'); ylabel('Quadrature')
title('Equalized PBCH Constellation');
m = max(abs([real(sym(:)); imag(sym(:))])) * 1.1;
axis([-m m -m m]);

% Display calculated EVM
disp([' PBCH RMS EVM: ' num2str(pbchEVMrms,'%0.3f') '%']);


[~,pbchIndicesInfo] = nrPBCHIndices(ncellid);

Qm = pbchIndicesInfo.G / pbchIndicesInfo.Gd;
csi = repmat(csi.',Qm,1);
csi = reshape(csi,[],1);

% Apply CSI
cw = cw .* csi;

end