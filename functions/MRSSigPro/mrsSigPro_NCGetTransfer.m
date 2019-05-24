function [fdata,proclog] = mrsSigPro_NCGetTransfer(fdata,proclog,refChannel,detectChannel)

if ~isnan(refChannel)
    if ~isnan(detectChannel)
%         switch fdata.info.device
% MMP
% noise records are no longer used since NC can be based on the record
% itself thats the same for both GMR and Numis
%             case 'GMR'               
                niQ = mrsSigPro_GetGMRZeroPuls(fdata);
                if ~isempty(niQ)
                    for iirx=1:length(detectChannel)
                        for iiq = 1:length(niQ)
                            for iirec = 1:length(fdata.Q(iiq).rec)
                                detectKeep((iiq-1)*length(fdata.Q(iiq).rec) + iirec) = ...
                                     mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),2);
                                detection((iiq-1)*length(fdata.Q(iiq).rec) + iirec).P1 =  ...
                                    fdata.Q(iiq).rec(iirec).rx(detectChannel(iirx)).sig(2).v1;                               
                                for rc=1:length(refChannel)
                                    referenceKeep(rc,(iiq-1)*length(fdata.Q(iiq).rec) + iirec) = ...
                                        mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),2);
                                    reference((iiq-1)*length(fdata.Q(iiq).rec) + iirec).R1(rc,:) =  ...
                                        fdata.Q(iiq).rec(iirec).rx(refChannel(rc)).sig(2).v1;
                                end
                            end
                        end
                        detection((sum(referenceKeep)+detectKeep)==0)=[]; %  include only if all (detection and reference) are set keep 
                        reference((sum(referenceKeep)+detectKeep)==0)=[];
                        
%                         % JW: probably obsolete - save/get from proclog
%                         fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(2).transfer   = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
%                         fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(2).refChannel = refChannel;
                        
                        % save TF to proclog
                        proclog.NC.rx(detectChannel(iirx)).sig(2).TF = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
                        proclog.NC.rx(detectChannel(iirx)).sig(2).niref = refChannel;
                        proclog.NC.rx(detectChannel(iirx)).sig(2).niQ = niQ;
                        proclog.NC.rx(detectChannel(iirx)).sig(2).nirec = ones(1,length(fdata.Q(iiq).rec));
                        
                        figure;
                            t        = fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(2).t0;
                            freqMax  = 1/2/(t(2)-t(1));
                            freqSpec = linspace(0,2*freqMax, length(t));
%                            plot(freqSpec,abs(fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(2).transfer));xlim([1500 2500]);
                            plot(freqSpec,abs(proclog.NC.rx(detectChannel(iirx)).sig(2).TF));xlim([1500 2500]);
                    end
                    
                    if fdata.Q(1).rec(1).rx(detectChannel(1)).sig(3).recorded
                        clear detection reference detectKeep referenceKeep
                        for iirx=1:length(detectChannel)
                            for iiq = 1:length(niQ)
                                for iirec = 1:length(fdata.Q(iiq).rec)
                                    detectKeep((iiq-1)*length(fdata.Q(iiq).rec) + iirec) = ...
                                        mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),3);
                                    detection((iiq-1)*length(fdata.Q(iiq).rec) + iirec).P1 =  ...
                                        fdata.Q(iiq).rec(iirec).rx(detectChannel(iirx)).sig(3).v1;
                                    for rc=1:length(refChannel)
                                        referenceKeep(rc,(iiq-1)*length(fdata.Q(iiq).rec) + iirec) = ...
                                            mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),3);
                                        reference((iiq-1)*length(fdata.Q(iiq).rec) + iirec).R1(rc,:) =  ...
                                            fdata.Q(iiq).rec(iirec).rx(refChannel(rc)).sig(3).v1;
                                    end
                                end
                            end
                            detection((sum(referenceKeep)+detectKeep)==0)=[]; %  include only if all (detection and reference) are set keep
                            reference((sum(referenceKeep)+detectKeep)==0)=[];
                            
%                             % JW: probably obsolete - save/get from proclog
%                             fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(3).transfer   = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
%                             fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(3).refChannel = refChannel;
                            
                            % save TF to proclog
                            proclog.NC.rx(detectChannel(iirx)).sig(3).TF = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
                            proclog.NC.rx(detectChannel(iirx)).sig(3).niref = refChannel;
                            proclog.NC.rx(detectChannel(iirx)).sig(3).niQ = niQ;
                            proclog.NC.rx(detectChannel(iirx)).sig(3).nirec = ones(1,length(fdata.Q(iiq).rec));         
                            
                        end
                    end
                    
                else
                    msgbox('no transfer calculation possible')
                end
                
        
%             case 'NUMISpoly'
%                 switch type
%                     case 2 % Local
%                         for iiq = 1:length(fdata.Q)
%                             for iirx=1:length(detectChannel)
%                                 for iirec = 1:length(fdata.Q(iiq).rec)
%                                     detectKeep(iirec)   = mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),1);
%                                     detection(iirec).P1 = fdata.Q(iiq).rec(iirec).rx(detectChannel(iirx)).sig(1).v1;
%                                     for rc=1:length(refChannel)
%                                         referenceKeep(rc,iirec)   = mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),1);
%                                         reference(iirec).R1(rc,:) = fdata.Q(iiq).rec(iirec).rx(refChannel(rc)).sig(1).v1;
%                                     end
%                                 end
%                                 detection((sum(referenceKeep)+detectKeep)==0)=[]; %  include only if all (detection and reference) are set keep
%                                 reference((sum(referenceKeep)+detectKeep)==0)=[];
%                                 fdata.Q(iiq).rec(1).rx(detectChannel(iirx)).sig(2).transfer   = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
%                                 fdata.Q(iiq).rec(1).rx(detectChannel(iirx)).sig(2).refChannel = refChannel;
%                             end
%                         end
%                         % MMP what about NUMIS NC for 2 pulse sequences?
%                         % Length of noise records? Are there several noise records 
%                         % or only the one at the record beginning?
%                         % Until know all is based on exactly the same
%                         % length of noise and FID record. Think this is not
%                         % given for Numis 2 pulse sequences 
%                     case 1 % 'Global'
%                         for iirx=1:length(detectChannel)
%                             for iiq = 1:length(fdata.Q)
%                                 for iirec = 1:length(fdata.Q(iiq).rec)
%                                     detectKeep((iiq-1)*length(fdata.Q(iiq).rec) + iirec) = ...
%                                         mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),1);
%                                     detection((iiq-1)*length(fdata.Q(iiq).rec) + iirec).P1 =  ...
%                                         fdata.Q(iiq).rec(iirec).rx(detectChannel(iirx)).sig(1).v1;
%                                     for rc=1:length(refChannel)
%                                         referenceKeep(rc,(iiq-1)*length(fdata.Q(iiq).rec) + iirec) = ...
%                                             mrs_getkeep(proclog,iiq,iirec,detectChannel(iirx),1);
%                                         reference((iiq-1)*length(fdata.Q(iiq).rec) + iirec).R1(rc,:) =  ...
%                                             fdata.Q(iiq).rec(iirec).rx(refChannel(rc)).sig(1).v1;
%                                     end
%                                 end
%                             end
%                             detection((sum(referenceKeep)+detectKeep)==0)=[]; %  include only if all (detection and reference) are set keep 
%                             reference((sum(referenceKeep)+detectKeep)==0)=[];
%                             fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(2).transfer   = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
%                             fdata.Q(1).rec(1).rx(detectChannel(iirx)).sig(2).refChannel = refChannel;
%                         end
%                         
%                 end
%         end
    else
        msgbox('enter at least one detection channel')
    end
else
    msgbox('enter at least one reference channel')
end
       