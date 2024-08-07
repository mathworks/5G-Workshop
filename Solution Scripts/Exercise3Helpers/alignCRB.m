
function [rxWaveform,fPhaseComp,nrb]=alignCRB(initialSystemInfo,frameOffset,rxWaveform,fPhaseComp,sampleRate,config)

k_SSB = initialSystemInfo.k_SSB;  % KSSB indicates the frequency offset of the SSB from that CRB raster. 
scsCommon = initialSystemInfo.SubcarrierSpacingCommon;



% Subcarrier spacing of k_SSB, as defined in TS 38.211 Section 7.4.3.1

    if scsCommon > 30  % FR2
        scsKSSB = scsCommon;
    else
        scsKSSB = 15;
    end



kFreqShift = k_SSB*scsKSSB*1e3;
rxWaveform = rxWaveform.*exp(1i*2*pi*kFreqShift*(0:length(rxWaveform)-1)'/sampleRate);


% Adjust the symbol phase compensation frequency with the frequency shift
% introduced.
fPhaseComp = fPhaseComp - kFreqShift;

% Add leading zeros
zeroPadding = zeros(-min(frameOffset,0),size(rxWaveform,2));
rxWaveform = [zeroPadding; rxWaveform(1+max(frameOffset,0):end,:)];



% Determine the number of resource blocks and subcarrier spacing for OFDM
% demodulation of CORESET 0.
minChannelBW=config.MinChannelBW;
nrb = hCORESET0DemodulationBandwidth(initialSystemInfo,scsSSB,minChannelBW);   

if sampleRate < nrb*12*scsCommon*1e3
    disp(['SIB1 recovery cannot continue. CORESET 0 resources are beyond '...
          'the frequency limits of the received waveform for the sampling rate configured.']);
    return;
end

end