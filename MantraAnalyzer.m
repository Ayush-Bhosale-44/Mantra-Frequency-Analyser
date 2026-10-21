function MantraDashboard
%MANTRA FREQUENCY ANALYZER
% A MATLAB-native interactive dashboard. Save as HinduMantraDashboard.m
% Run with: HinduMantraDashboard

    bg = [0.055 0.075 0.12];
    panelBg = [0.09 0.115 0.17];
    cardBg = [0.12 0.15 0.21];
    accent = [0.28 0.78 0.70];
    txt = [0.92 0.95 0.98];
    muted = [0.63 0.70 0.79];

    S.audio = [];
    S.fs = [];
    S.file = '';
    S.player = [];
    S.filtered = [];
    S.last = struct();

    fig = uifigure('Name','Mantra Frequency Analyzer', ...
        'Color',bg,'Position',[60 50 1450 900], ...
        'Resize','on');
    fig.WindowState = 'maximized';
    root = uigridlayout(fig,[3 2]);
    root.RowHeight = {72,105,'1x'};
    root.ColumnWidth = {255,'1x'};
    root.Padding = [18 16 18 16];
    root.RowSpacing = 12; root.ColumnSpacing = 14;
    root.BackgroundColor = bg;

    % Header
    header = uipanel(root,'BackgroundColor',panelBg,'BorderType','none');
    header.Layout.Row = 1; header.Layout.Column = [1 2];
    hg = uigridlayout(header,[1 2]);
    hg.ColumnWidth = {'1x',220}; hg.Padding = [18 8 18 8];
    titleBox = uipanel(hg,'BackgroundColor',panelBg,'BorderType','none');
    titleBox.Layout.Column = 1;
    tg = uigridlayout(titleBox,[2 1]); tg.RowHeight = {32,20}; tg.Padding = [0 0 0 0]; tg.RowSpacing = 0;
    uilabel(tg,'Text','FREQUENCY ANALYZER','FontSize',21,'FontWeight','bold','FontColor',txt,'BackgroundColor',panelBg);
    uilabel(tg,'Text','Audio signal processing • spectral analysis • chanting rhythm','FontSize',11,'FontColor',muted,'BackgroundColor',panelBg);
    status = uilabel(hg,'Text','●  READY','FontSize',12,'FontWeight','bold','FontColor',accent,'HorizontalAlignment','right','BackgroundColor',panelBg);
    status.Layout.Column = 2;

    % Sidebar settings
    side = uipanel(root,'BackgroundColor',panelBg,'BorderType','none','Title','  ANALYSIS CONTROLS','ForegroundColor',txt,'FontWeight','bold');
    side.Layout.Row = [2 3]; side.Layout.Column = 1;
    sg = uigridlayout(side,[16 1]);
    sg.RowHeight = {38,36,22,30,22,30,22,30,22,30,22,30,42,42,34,'1x'};
    sg.Padding = [14 12 14 12]; sg.RowSpacing = 8;
    loadBtn = uibutton(sg,'push','Text','＋  Load audio file','FontSize',13,'FontWeight','bold','BackgroundColor',accent,'FontColor',[0.03 0.08 0.11], 'ButtonPushedFcn',@loadAudio);
    info = uilabel(sg,'Text','No audio loaded','FontSize',10,'FontColor',muted,'WordWrap','on');
    addLabel(sg,'FILTER TYPE');
    filterDrop = uidropdown(sg,'Items',{'None','Low-pass','High-pass'},'Value','None','BackgroundColor',cardBg,'FontColor',txt);
    addLabel(sg,'CUTOFF FREQUENCY (Hz)');
    cutoff = uieditfield(sg,'numeric','Value',1000,'Limits',[20 20000],'RoundFractionalValues','on','BackgroundColor',cardBg,'FontColor',txt);
    addLabel(sg,'ENERGY FRAME (ms)');
    frameMs = uieditfield(sg,'numeric','Value',40,'Limits',[10 500],'RoundFractionalValues','on','BackgroundColor',cardBg,'FontColor',txt);
    addLabel(sg,'PULSE SENSITIVITY');
    sensitivity = uislider(sg,'Limits',[1.1 3.5],'Value',1.7); sensitivity.MajorTicks = [1.1 1.7 2.3 2.9 3.5];
    addLabel(sg,'MAX AUDIO DURATION (s)');
    maxDur = uieditfield(sg,'numeric','Value',180,'Limits',[5 3600],'RoundFractionalValues','on','BackgroundColor',cardBg,'FontColor',txt);
    analyzeBtn = uibutton(sg,'push','Text','▶  Analyze audio','FontSize',13,'FontWeight','bold','BackgroundColor',[0.20 0.48 0.72],'FontColor',[1 1 1],'ButtonPushedFcn',@analyzeAudio);
    playBtn = uibutton(sg,'push','Text','♫  Play / Stop','FontSize',12,'BackgroundColor',cardBg,'FontColor',txt,'ButtonPushedFcn',@playAudio);
    exportBtn = uibutton(sg,'push','Text','↓  Export report (CSV)','FontSize',12,'BackgroundColor',cardBg,'FontColor',txt,'ButtonPushedFcn',@exportReport);
    uilabel(sg,'Text','Tip: use a clear recording with minimal background noise for better pitch and rhythm estimates.','FontSize',10,'FontColor',muted,'WordWrap','on');

    % KPI cards
    metrics = uigridlayout(root,[1 4]);
    metrics.Layout.Row = 2; metrics.Layout.Column = 2;
    metrics.ColumnWidth = {'1x','1x','1x','1x'}; metrics.Padding = [0 0 0 0]; metrics.ColumnSpacing = 10;
    [durationVal,durationUnit] = makeCard(metrics,'DURATION','—','seconds');
    [pitchVal,pitchUnit] = makeCard(metrics,'DOMINANT FREQUENCY','—','Hz');
    [rmsVal,rmsUnit] = makeCard(metrics,'RMS LEVEL','—','amplitude');
    [pulseVal,pulseUnit] = makeCard(metrics,'ENERGY PULSES','—','detected');

    % Plot area
    plotPanel = uipanel(root,'BackgroundColor',bg,'BorderType','none');
    plotPanel.Layout.Row = 3; plotPanel.Layout.Column = 2;
    pg = uigridlayout(plotPanel,[2 2]);
    pg.RowHeight = {'1x','1x'}; pg.ColumnWidth = {'1x','1x'};
    pg.Padding = [0 0 0 0]; pg.RowSpacing = 12; pg.ColumnSpacing = 12;
    axWave = makeAxes(pg,'Waveform','Time (s)','Amplitude');
    axFFT = makeAxes(pg,'Frequency Spectrum','Frequency (Hz)','Magnitude');
    axSpec = makeAxes(pg,'Spectrogram','Time (s)','Frequency (Hz)');
    axEnergy = makeAxes(pg,'Chanting Rhythm / Energy','Time (s)','RMS energy');
    placeholder(axWave,'Load an audio file to begin');
    placeholder(axFFT,'Frequency spectrum appears here');
    placeholder(axSpec,'Spectrogram appears here');
    placeholder(axEnergy,'Energy pulses appear here');

    function addLabel(parent,str)
        uilabel(parent,'Text',str,'FontSize',10,'FontWeight','bold','FontColor',muted,'BackgroundColor',panelBg);
    end
    function [v,u] = makeCard(parent,heading,value,unit)
        p = uipanel(parent,'BackgroundColor',cardBg,'BorderType','none');
        g = uigridlayout(p,[3 1]); g.RowHeight = {22,36,18}; g.Padding = [12 8 12 6]; g.RowSpacing = 0;
        uilabel(g,'Text',heading,'FontSize',9,'FontWeight','bold','FontColor',muted,'BackgroundColor',cardBg);
        v = uilabel(g,'Text',value,'FontSize',25,'FontWeight','bold','FontColor',txt,'BackgroundColor',cardBg);
        u = uilabel(g,'Text',unit,'FontSize',9,'FontColor',muted,'BackgroundColor',cardBg);
    end
    function ax = makeAxes(parent,heading,xlab,ylab)
        p = uipanel(parent,'BackgroundColor',panelBg,'BorderType','none','Title',['  ' upper(heading)],'ForegroundColor',txt,'FontWeight','bold');
        p.Layout.Row = ceil((nAxes()+1)/2); %#ok<NASGU>
        ax = uiaxes(p,'Position',[48 35 480 280]);
        ax.Color = panelBg; ax.XColor = muted; ax.YColor = muted; ax.GridColor = [0.28 0.33 0.41];
        ax.FontSize = 9; ax.Box = 'off'; grid(ax,'on');
        xlabel(ax,xlab,'Color',muted); ylabel(ax,ylab,'Color',muted);
        ax.Toolbar.Visible = 'off';
        % Keep chart panels responsive by using a panel grid within the plotting area.
        p.SizeChangedFcn = @(~,~) resizeAxis(p,ax);
        ax.UserData = heading;
        % register axes order
        if ~isappdata(fig,'axisCount'), setappdata(fig,'axisCount',0); end
        c = getappdata(fig,'axisCount') + 1; setappdata(fig,'axisCount',c);
        if c <= 4
            p.Layout.Row = ceil(c/2); p.Layout.Column = mod(c-1,2)+1;
        end
    end
    function n = nAxes()
        if isappdata(fig,'axisCount'), n=getappdata(fig,'axisCount'); else, n=0; end
    end
    function resizeAxis(p,ax)
        w = p.Position(3); h = p.Position(4);
        ax.Position = [48 35 max(100,w-62) max(100,h-48)];
    end
    function placeholder(ax,msg)
        cla(ax); text(ax,0.5,0.5,msg,'Units','normalized','HorizontalAlignment','center','Color',muted,'FontSize',11);
        ax.XTick = []; ax.YTick = [];
    end

    function loadAudio(~,~)
        [f,p] = uigetfile({'*.wav;*.mp3;*.m4a;*.flac;*.ogg','Audio files';'*.*','All files'},'Choose a mantra recording');
        if isequal(f,0), return; end
        try
            [y,fs] = audioread(fullfile(p,f));
            if size(y,2)>1, y = mean(y,2); end
            limit = maxDur.Value;
            if numel(y)>round(limit*fs), y=y(1:round(limit*fs)); end
            S.audio = y(:); S.fs = fs; S.file = fullfile(p,f); S.filtered = [];
            S.last = struct();
            info.Text = sprintf('%s\n%.1f s • %d Hz',f,numel(y)/fs,fs);
            durationVal.Text = sprintf('%.1f',numel(y)/fs);
            pitchVal.Text = '—'; rmsVal.Text = '—'; pulseVal.Text = '—';
            status.Text = '●  AUDIO LOADED'; status.FontColor = accent;
            placeholder(axWave,'Press Analyze audio to plot waveform');
            placeholder(axFFT,'Frequency spectrum appears here'); placeholder(axSpec,'Spectrogram appears here'); placeholder(axEnergy,'Energy pulses appear here');
        catch ME
            uialert(fig,ME.message,'Could not load audio');
        end
    end

    function playAudio(~,~)
        if isempty(S.audio), uialert(fig,'Load an audio file first.','No audio'); return; end
        try
            if ~isempty(S.player) && isplaying(S.player)
                stop(S.player); playBtn.Text = '♫  Play / Stop';
            else
                if ~isempty(S.filtered), toPlay=S.filtered; else, toPlay=S.audio; end
                S.player = audioplayer(toPlay,S.fs);
                play(S.player); playBtn.Text = '■  Stop playback';
            end
        catch ME
            uialert(fig,ME.message,'Playback error');
        end
    end

    function analyzeAudio(~,~)
        if isempty(S.audio), uialert(fig,'Load an audio file first.','No audio'); return; end
        status.Text = '●  ANALYZING…'; status.FontColor = [1 0.72 0.28]; drawnow;
        try
            y = S.audio; fs = S.fs;
            if numel(y)>round(maxDur.Value*fs), y=y(1:round(maxDur.Value*fs)); end
            yf = y;
            kind = filterDrop.Value; fc = min(cutoff.Value,0.48*fs);
            if ~strcmp(kind,'None')
                yf = applyFIR(y,fs,fc,kind);
            end
            S.filtered = yf;
            N = numel(yf); t = (0:N-1)'/fs;
            % RMS in overlapping short frames
            frame = max(16,round(frameMs.Value*fs/1000)); hop=max(1,round(frame/2));
            starts = 1:hop:max(1,N-frame+1);
            en = zeros(numel(starts),1); et = zeros(numel(starts),1);
            for k=1:numel(starts)
                ix=starts(k):min(N,starts(k)+frame-1); en(k)=sqrt(mean(yf(ix).^2)); et(k)=mean(ix)/fs;
            end
            % Dominant frequency (exclude DC)
            nfft = 2^nextpow2(min(max(N,2048),262144));
            if N>nfft, xfft=yf(1:nfft); else, xfft=yf; end
            xfft=xfft(:); xfft=xfft-mean(xfft); win=0.5-0.5*cos(2*pi*(0:numel(xfft)-1)'/max(1,numel(xfft)-1));
            mag=abs(fft(xfft.*win,nfft)); half=floor(nfft/2)+1; mag=mag(1:half); freq=(0:half-1)'*fs/nfft;
            if numel(mag)>1, [~,im]=max(mag(2:end)); im=im+1; dom=freq(im); else, dom=0; end
            % Rough pitch via autocorrelation, limited to plausible vocal range
            pitch = estimatePitch(yf,fs);
            % Pulse detection: smooth energy, then peaks above average x sensitivity
            smoothN=max(1,round(0.12*fs/hop)); ens=movmean(en,smoothN);
            threshold = mean(ens)+sensitivity.Value*std(ens);
            peaks=[];
            for k=2:numel(ens)-1
                if ens(k)>ens(k-1) && ens(k)>=ens(k+1) && ens(k)>threshold
                    if isempty(peaks) || et(k)-et(peaks(end))>0.18, peaks(end+1)=k; %#ok<AGROW>
                    elseif ens(k)>ens(peaks(end)), peaks(end)=k; end
                end
            end
            pulseTimes=et(peaks);
            % Draw waveform
            cla(axWave); plot(axWave,t,yf,'Color',accent,'LineWidth',0.75); grid(axWave,'on');
            xlabel(axWave,'Time (s)'); ylabel(axWave,'Amplitude'); title(axWave,sprintf('Filtered waveform • %d samples',N),'Color',txt,'FontWeight','normal');
            % Spectrum
            cla(axFFT); plot(axFFT,freq,mag,'Color',[0.48 0.69 1.0],'LineWidth',1); xlim(axFFT,[0 min(fs/2,8000)]); grid(axFFT,'on');
            xlabel(axFFT,'Frequency (Hz)'); ylabel(axFFT,'Magnitude'); title(axFFT,sprintf('Dominant bin: %.1f Hz',dom),'Color',txt,'FontWeight','normal');
            % Spectrogram using built-in spectrogram when available, otherwise STFT
            cla(axSpec);
            winLen=min(1024,max(128,2^floor(log2(max(128,min(N,1024)))))); ov=floor(0.75*winLen); nsp=max(256,winLen);
            [F,Tspec,P] = localSpectrogram(yf,fs,winLen,ov,nsp);
            imagesc(axSpec,Tspec,F,10*log10(P+eps)); axis(axSpec,'xy'); ylim(axSpec,[0 min(fs/2,5000)]); colormap(axSpec,'parula');
            xlabel(axSpec,'Time (s)'); ylabel(axSpec,'Frequency (Hz)'); title(axSpec,'Short-time spectral energy','Color',txt,'FontWeight','normal');
            % Energy rhythm
            cla(axEnergy); plot(axEnergy,et,en,'Color',[0.58 0.72 1.0],'LineWidth',1); hold(axEnergy,'on');
            yline(axEnergy,threshold,'--','Threshold','Color',[1 0.65 0.35]);
            if ~isempty(peaks), scatter(axEnergy,pulseTimes,en(peaks),26,[1 0.65 0.35],'filled'); end
            hold(axEnergy,'off'); grid(axEnergy,'on'); xlabel(axEnergy,'Time (s)'); ylabel(axEnergy,'RMS energy');
            title(axEnergy,sprintf('%d candidate energy pulses',numel(peaks)),'Color',txt,'FontWeight','normal');
            % KPI cards and data for export
            durationVal.Text=sprintf('%.1f',N/fs); pitchVal.Text=sprintf('%.1f',dom); rmsVal.Text=sprintf('%.4f',sqrt(mean(yf.^2))); pulseVal.Text=sprintf('%d',numel(peaks));
            S.last = struct('duration',N/fs,'sampleRate',fs,'dominantFrequency',dom,'estimatedPitch',pitch,'rms',sqrt(mean(yf.^2)), ...
                'peak',max(abs(yf)),'pulseTimes',pulseTimes(:),'pulseCount',numel(peaks),'energyTime',et(:),'energy',en(:), ...
                'spectrumFrequency',freq(:),'spectrumMagnitude',mag(:),'waveTime',t(:),'waveform',yf(:),'filter',kind,'cutoff',fc);
            status.Text=sprintf('●  ANALYSIS COMPLETE  •  pitch estimate %.1f Hz',pitch); status.FontColor=accent;
        catch ME
            status.Text='●  ANALYSIS ERROR'; status.FontColor=[1 0.35 0.35];
            uialert(fig,ME.message,'Analysis failed');
        end
    end

    function exportReport(~,~)
        if isempty(fieldnames(S.last)), uialert(fig,'Analyze the audio before exporting.','Nothing to export'); return; end
        [f,p]=uiputfile('mantra_analysis_summary.csv','Save analysis summary');
        if isequal(f,0), return; end
        try
            R=S.last;
            names={'Metric';'Duration (s)';'Sample rate (Hz)';'Dominant frequency (Hz)';'Estimated pitch (Hz)';'RMS amplitude';'Peak amplitude';'Energy pulse count';'Filter';'Cutoff frequency (Hz)'};
            values={'Value';R.duration;R.sampleRate;R.dominantFrequency;R.estimatedPitch;R.rms;R.peak;R.pulseCount;R.filter;R.cutoff};
            T=table(names,values,'VariableNames',{'Metric','Value'});
            writetable(T,fullfile(p,f));
            [folder,base]=fileparts(fullfile(p,f));
            writetable(table(R.energyTime,R.energy,'VariableNames',{'Time_s','RMS_Energy'}),fullfile(folder,[base '_energy.csv']));
            writetable(table(R.spectrumFrequency,R.spectrumMagnitude,'VariableNames',{'Frequency_Hz','Magnitude'}),fullfile(folder,[base '_spectrum.csv']));
            writetable(table(R.pulseTimes,'VariableNames',{'Pulse_Time_s'}),fullfile(folder,[base '_pulse_times.csv']));
            uialert(fig,'Summary and detailed CSV files exported successfully.','Export complete','Icon','success');
        catch ME
            uialert(fig,ME.message,'Export failed');
        end
    end

    function [F,Tspec,P] = localSpectrogram(x,fs,winLen,overlap,nfftSpec)
        % Short-time Fourier transform implemented with base MATLAB functions.
        x=x(:); hop=max(1,winLen-overlap); starts=1:hop:max(1,numel(x)-winLen+1);
        if isempty(starts), starts=1; end
        w=0.5-0.5*cos(2*pi*(0:winLen-1)'/max(1,winLen-1));
        P=zeros(floor(nfftSpec/2)+1,numel(starts));
        for ii=1:numel(starts)
            ix=starts(ii):min(numel(x),starts(ii)+winLen-1); frame=zeros(winLen,1);
            frame(1:numel(ix))=x(ix); frame=frame.*w;
            X=fft(frame,nfftSpec); P(:,ii)=abs(X(1:floor(nfftSpec/2)+1)).^2/(sum(w.^2)+eps);
        end
        F=(0:floor(nfftSpec/2))'*fs/nfftSpec; Tspec=(starts-1+winLen/2)/fs;
    end

    function yout=applyFIR(x,fs,fc,kind)
        % Windowed-sinc FIR filter, no Signal Processing Toolbox required.
        fc=max(1,min(fc,0.48*fs)); order=160; n=(-order/2:order/2)'; normFc=fc/fs;
        if strcmp(kind,'Low-pass')
            h=2*normFc*localSinc(2*normFc*n);
        else
            h=-2*normFc*localSinc(2*normFc*n); h(order/2+1)=h(order/2+1)+1;
        end
        w=0.54-0.46*cos(2*pi*(0:order)'/order); h=h.*w; h=h/(sum(h)+eps);
        if strcmp(kind,'High-pass'), h=h-mean(h); end
        yout=conv(x,h,'same');
    end
    function z=localSinc(x)
        z=ones(size(x)); ix=abs(x)>1e-12; z(ix)=sin(pi*x(ix))./(pi*x(ix));
    end
    function f0=estimatePitch(x,fs)
        x=x(:); x=x-mean(x); maxN=min(numel(x),round(2*fs)); x=x(1:maxN);
        if numel(x)<round(0.08*fs), f0=0; return; end
        % Downsample only for efficient autocorrelation
        dec=max(1,floor(fs/8000)); x=x(1:dec:end); fss=fs/dec;
        x=x(1:min(numel(x),round(1.5*fss)));
        ac=conv(x,flipud(x)); ac=ac(numel(x):end); ac=ac/(ac(1)+eps);
        lagMin=max(1,floor(fss/500)); lagMax=min(numel(ac),ceil(fss/65));
        if lagMax<=lagMin, f0=0; return; end
        [~,ix]=max(ac(lagMin:lagMax)); lag=lagMin+ix-1; f0=fss/lag;
    end
end
