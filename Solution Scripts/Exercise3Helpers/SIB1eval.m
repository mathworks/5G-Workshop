function SIB1eval(initialSystemInfo,rxWaveform,fPhaseComp,frameOffset,nLeadingFrames,sampleRate,config)
% Adjust timing offset to the frame origin of the first frame that can
% schedule an SS/PBCH block.
%[frameOffset,nLeadingFrames] = hTimingOffsetToFirstFrame(timingOffset,refBurst,ssbIndex,nHalfFrame,sampleRate);

% Align CRB and determine the number of resource blocks and subcarrier spacing for OFDM
% demodulation of CORESET 0.
[rxWaveform,fPhaseComp,nrb]=OFDMdemodprep(initialSystemInfo,frameOffset,rxWaveform,fPhaseComp,sampleRate,config);

% OFDM demodulate received waveform with common subcarrier spacing
nSlot = 0;
scsCommon = initialSystemInfo.SubcarrierSpacingCommon;
rxGrid = nrOFDMDemodulate(rxWaveform, nrb, scsCommon, nSlot,...
                         'SampleRate',sampleRate,'CarrierFrequency',fPhaseComp);

% Display OFDM resource grid and highlight strongest SS block
plotResourceGrid(rxGrid,refBurst,initialSystemInfo,nLeadingFrames,ssbIndex,nHalfFrame)


initialSystemInfo.NFrame = mod(initialSystemInfo.NFrame - nLeadingFrames,1024);
numRxSym = size(rxGrid,2);
[csetSubcarriers,monSlots,monSlotsSym,ssStartSym] = hPDCCH0MonitoringResources(initialSystemInfo,scsSSB,minChannelBW,ssbIndex,numRxSym);

% Check if search space is beyond end of waveform
if isempty(monSlotsSym)
    disp('Search space slot is beyond end of waveform.');
    return;
end

% Extract slots containing strongest PDCCH from the received grid
rxMonSlotGrid = rxGrid(csetSubcarriers,monSlotsSym,:);

scsPair = [scsSSB scsCommon];
[pdcch,csetPattern] = hPDCCH0Configuration(ssbIndex,initialSystemInfo,scsPair,ncellid,minChannelBW);

% Configure the carrier to span the BWP (CORESET 0)
carrier = hCarrierConfigSIB1(ncellid,initialSystemInfo,pdcch);

% Specify DCI message with Format 1_0 scrambled with SI-RNTI (TS 38.212
% Section 7.3.1.2.1)
dci = DCIFormat1_0_SIRNTI(pdcch.NSizeBWP);
symbolsPerSlot = 14;

[monSlotsSym,dciCRC,dcibits,aLevIdx,cIdx]=DCIsearch(monSlots,carrier,pdcch,rxMonSlotGrid,monSlotsSym,csetSubcarriers);

% Build DCI message structure
dci = fromBits(dci,dcibits);

% Get PDSCH configuration from cell ID, BCH information, and DCI
[pdsch,K0] = hSIB1PDSCHConfiguration(dci,pdcch.NSizeBWP,initialSystemInfo.DMRSTypeAPosition,csetPattern);

% For CORESET pattern 2, the gNodeB can allocate PDSCH in the next slot,
% which is indicated by the slot offset K_0 signaled by DCI. For more
% information, see TS 38.214 Table 5.1.2.1.1-4.
[carrier,monSlotsSym]=CORESET2check(carrier,K0,monSlotsSym,csetSubcarriers,rxGrid);

% PDSCH channel estimation and equalization using PDSCH DM-RS
pdschDmrsIndices = nrPDSCHDMRSIndices(carrier,pdsch);
pdschDmrsSymbols = nrPDSCHDMRS(carrier,pdsch);

mu = log2(scsCommon/15);
bw = 2^mu*100;   % Search bandwidth (kHz)
freqStep = 2^mu; % Frequency step (kHz)
freqSearch = -bw/2:freqStep:bw/2-freqStep;
[~,fSearchIdx] = sort(abs(freqSearch)); % Sort frequencies from center
freqSearch = freqSearch(fSearchIdx);

for fpc = fPhaseComp + 1e3*freqSearch
    
    % OFDM demodulate received waveform
    nSlot = 0;
    rxGrid = nrOFDMDemodulate(rxWaveform, nrb, scsCommon, nSlot,...
                                'SampleRate',sampleRate,'CarrierFrequency',fpc);
   
    % Extract monitoring slot from the received grid   
    rxSlotGrid = rxGrid(csetSubcarriers,monSlotsSym,:);
    rxSlotGrid = rxSlotGrid/max(abs(rxSlotGrid(:))); % Normalization of received RE magnitude
    
    % Channel estimation and equalization of PDSCH symbols
    [hest,nVar,pdschHestInfo] = nrChannelEstimate(rxSlotGrid,pdschDmrsIndices,pdschDmrsSymbols);
    [pdschIndices,pdschIndicesInfo] = nrPDSCHIndices(carrier,pdsch);
    [pdschRxSym,pdschHest] = nrExtractResources(pdschIndices,rxSlotGrid,hest);
    pdschEqSym = nrEqualizeMMSE(pdschRxSym,pdschHest,nVar);
    
    % PDSCH demodulation
    cw = nrPDSCHDecode(carrier,pdsch,pdschEqSym,nVar);

    % Create and configure DL-SCH decoder with target code rate and
    % transport block size
    decodeDLSCH = nrDLSCHDecoder;
    decodeDLSCH.LDPCDecodingAlgorithm = 'Normalized min-sum';
    Xoh_PDSCH = 0; % TS 38.214 Section 5.1.3.2
    mcsTables = nrPDSCHMCSTables;
    qam64Table = mcsTables.QAM64Table; % TS 38.214 Table 5.1.3.1-1
    tcr = qam64Table.TargetCodeRate(qam64Table.MCSIndex==dci.ModulationCoding);
    NREPerPRB = pdschIndicesInfo.NREPerPRB;
    tbsLength = nrTBS(pdsch.Modulation,pdsch.NumLayers,length(pdsch.PRBSet),NREPerPRB,tcr,Xoh_PDSCH);
    decodeDLSCH.TransportBlockLength = tbsLength;
    decodeDLSCH.TargetCodeRate = tcr;
    
    % Decode DL-SCH
    [sib1bits,sib1CRC] = decodeDLSCH(cw,pdsch.Modulation,pdsch.NumLayers,dci.RedundancyVersion);
    
    if sib1CRC == 0
        break;
    end
    
end

% Highlight PDSCH and PDSCH DM-RS in resource grid.
pdcch.AggregationLevel = 2^(aLevIdx-2); 
pdcch.AllocatedCandidate = cIdx-1;
plotResourceGridSIB1(rxSlotGrid,carrier,pdcch,pdsch,tcr,K0);

SIB1results(pdschEqSym,carrier,pdsch,sib1CRC,cw)
end