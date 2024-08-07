
% Generate waveform containing SS burst and SIB1
function [nrbSSB ,sampleRate,rxWaveform,scsSSB,rxOfdmInfo,refBurst]=SIB1generation(config, SNRdB, offset)
% Configure and generate a waveform containing an SS burst and SIB1
wavegenConfig = hSIB1WaveformConfiguration(config);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% IMAN ADDED
% If the SSB and PDSCH have two diff subcarrier spacings, a second
% subcarrier is created for the SSB.
if numel(wavegenConfig.SCSCarriers) == 2
    scsCommon=wavegenConfig.SCSCarriers{1,1}.SubcarrierSpacing;
    scsSSB=wavegenConfig.SCSCarriers{1,2}.SubcarrierSpacing;
    wavegenConfig.SSBurst.Power = config.Power - 10*log10(scsSSB/scsCommon);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[txWaveform,waveInfo] = nrWaveformGenerator(wavegenConfig);
txOfdmInfo = waveInfo.ResourceGrids(1).Info;
boost = 6; % SNR boost in dB
% Add white Gaussian noise to the waveform. Note that the SNR only
% applies to the boosted SSB / SIB1
rng('default'); % Reset the random number generator
%SNRdB = 20; % SNR for AWGN
rxWaveform = awgn(txWaveform,SNRdB-boost,-10*log10(double(txOfdmInfo.Nfft)));

% Configure receiver
% Sample rate
sampleRate = txOfdmInfo.SampleRate;
%offset=1000;
rxWaveform=frequencyOffset(rxWaveform,sampleRate,offset);

% Symbol phase compensation frequency (Hz). The function
% nrWaveformGenerator does not apply symbol phase compensation to the
% generated waveform.
%fPhaseComp = 0; % Carrier center frequency (Hz) % Unused in this example

% Minimum channel bandwidth (MHz)
%minChannelBW = config.MinChannelBW; % Unused in this example

% Configure necessary burst parameters at the receiver
refBurst.BlockPattern = config.BlockPattern;
refBurst.L_max = numel(config.TransmittedBlocks);


% Get OFDM information from configured burst and receiver parameters
nrbSSB = 20;
scsSSB = hSSBurstSubcarrierSpacing(refBurst.BlockPattern);
rxOfdmInfo = nrOFDMInfo(nrbSSB,scsSSB,'SampleRate',sampleRate);

% Display spectrogram of received waveform
figure;
nfft = rxOfdmInfo.Nfft;
spectrogram(rxWaveform(:,1),ones(nfft,1),0,nfft,'centered',sampleRate,'yaxis','MinThreshold',-130);
title('Spectrogram of the Received Waveform')

end