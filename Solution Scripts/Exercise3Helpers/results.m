
function results(pdschEqSym,carrier,pdsch,sib1CRC,cw)

% Plot received PDSCH constellation after equalization
figure;
plot(pdschEqSym,'o');
xlabel('In-Phase'); ylabel('Quadrature')
title('Equalized PDSCH Constellation');
m = max(abs([real(pdschEqSym(:)); imag(pdschEqSym(:))])) * 1.1;
axis([-m m -m m]);

% Calculate RMS PDSCH EVM, including normalization of PDSCH symbols for any
% offset between DM-RS and PDSCH power
pdschRef = nrPDSCH(carrier,pdsch,double(cw{1}<0));
evm = comm.EVM;
pdschEVMrms = evm(pdschRef,pdschEqSym/sqrt(var(pdschEqSym)));

% Display PDSCH EVM and DL-SCH CRC
disp([' PDSCH RMS EVM: ' num2str(pdschEVMrms,'%0.3f') '%']);

disp([' PDSCH CRC: ' num2str(sib1CRC)]);


if sib1CRC == 0
    disp(' SIB1 decoding succeeded.');
else
    disp(' SIB1 decoding failed.');
end

end