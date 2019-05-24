function fdata    = mrsSigPro_NCDo(fdata,proclog,iQ,irec,irx,isig,type,refChannel)
% function fdata    = mrsSigPro_NCDo(fdata,iQ,irec,irx,isig,type,refChannel,detectChannel)

% JW may 2012
% Run NC only on currently selected receiver irx. Loop over multiple rx
% outside of this function. In this way it's possible to do NC only for the 
% currently selected receiver. 

% MMP feb./2012
% noise records are no longer used since NC can be based on the records of
% detection and reference itself. thats the same for both GMR and Numis
% switch fdata.info.device
%     case 'GMR'
        switch type
            case 1 % global --> use precalc. transfer
%                 transfer   = fdata.Q(1).rec(1).rx(irx).sig(isig).transfer;
%                 refChannel = fdata.Q(1).rec(1).rx(irx).sig(isig).refChannel;
                transfer   = proclog.NC.rx(irx).sig(isig).TF;
                refChannel = proclog.NC.rx(irx).sig(isig).niref;
            case 2 % local --> on the fly transfer
                nsection = 30;
                total    = length(fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1);
                section  = floor(total/nsection);
                for isection=1:nsection
                    % fill with zeros
                    detection(isection).P1(1:total) = 0;
                    % each section into separate pseudo record
                    detection(isection).P1(1:section) = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1( 1+(isection-1)*section : isection*section);%detection(isection).P1(section+1:total) = 0;
                    for rc=1:length(refChannel)
                        reference(isection).R1(rc,1:total) = 0;
                        reference(isection).R1(rc,1:section) = fdata.Q(iQ).rec(irec).rx(refChannel(rc)).sig(isig).v1( 1+(isection-1)*section : isection*section);                           
                    end
                end
                transfer   = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
                %fdata.Q(iQ).rec(irec).rx(irx).sig(isig).transfer = transfer;
                 
                     t        = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t0;
                     freqMax  = 1/2/(t(2)-t(1));
                     freqSpec = linspace(0,2*freqMax, length(t));
                    
%                     figure(13);
%                     freqLim=[1500 3500];
%                     hold on;
%                     imagesc(irec*ones(size(transfer(freqSpec>freqLim(1) & freqSpec<freqLim(2)))),...
%                            freqSpec(freqSpec>freqLim(1) & freqSpec<freqLim(2)),...
%                            abs(transfer(freqSpec>freqLim(1) & freqSpec<freqLim(2))));
%                      hold on;
%                      if ~mod(iQ,2)
%                         nb = (25-iQ) + (irec-1)*24;
%                         imagesc((nb -(25-iQ-1)/2 +12)*ones(size(transfer(freqSpec>freqLim(1) & freqSpec<freqLim(2)))),...
%                            freqSpec(freqSpec>freqLim(1) & freqSpec<freqLim(2)),...
%                            abs(transfer(freqSpec>freqLim(1) & freqSpec<freqLim(2))));
%                      else
%                         nb = (25-iQ) + (irec-1)*24;
%                         imagesc((nb -(25-iQ)/2 )*ones(size(transfer(freqSpec>freqLim(1) & freqSpec<freqLim(2)))),...
%                            freqSpec(freqSpec>freqLim(1) & freqSpec<freqLim(2)),...
%                            abs(transfer(freqSpec>freqLim(1) & freqSpec<freqLim(2))));
%                      end
        end
%     case 'NUMISpoly'
%         switch type
%             case 1
%                 transfer   = fdata.Q(1).rec(1).rx(irx).sig(isig).transfer;
%                 refChannel = fdata.Q(1).rec(1).rx(irx).sig(isig).refChannel;
%             case 2
%             
%         end
% end
transReference=zeros(size(fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1));
for nc=1:length(refChannel)
    transReference = transReference + ifft((transfer(:,nc).').*fft(fdata.Q(iQ).rec(irec).rx(refChannel(nc)).sig(isig).v1));
end

fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 - transReference;

% %         switch type
% %             case 1 % global --> use precalc. transfer
% %                 transfer   = fdata.Q(1).rec(1).rx(irx).sig(isig).transfer;
% %                 refChannel = fdata.Q(1).rec(1).rx(irx).sig(isig).refChannel;
% %             case 2 % local --> on the fly transfer
% %                 nsection = 16;
% %                 total    = length(fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1);
% %                 section  = floor(total/nsection);
% %                 for isection=1:nsection
% %                     for iirx=1:length(detectChannel)
% %                         % each section into separate pseudo record
% %                         detection(isection).P1 = fdata.Q(iQ).rec(irec).rx(detectChannel(iirx)).sig(isig).v1( 1+(isection-1)*section : isection*section);
% %                         % fill with zeros
% %                         detection(isection).P1(section+1:total) = 0;
% %                         for rc=1:length(refChannel)
% %                             reference(isection).R1(rc,1:section) = fdata.Q(iQ).rec(irec).rx(refChannel(rc)).sig(isig).v1( 1+(isection-1)*section : isection*section);
% %                             reference(isection).R1(rc,section+1:total) = 0;                           
% %                         end
% %                     end
% %                 end
% %                 transfer   = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
% %         end
% % %     case 'NUMISpoly'
% % %         switch type
% % %             case 1
% % %                 transfer   = fdata.Q(1).rec(1).rx(irx).sig(isig).transfer;
% % %                 refChannel = fdata.Q(1).rec(1).rx(irx).sig(isig).refChannel;
% % %             case 2
% % %             
% % %         end
% % % end
% % 
% % transReference=zeros(size(fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1));
% % for nc=1:length(refChannel)
% %     transReference = transReference + ifft((transfer(:,nc).').*fft(fdata.Q(iQ).rec(irec).rx(refChannel(nc)).sig(isig).v1));
% % end
% % 
% % fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 - transReference;
        