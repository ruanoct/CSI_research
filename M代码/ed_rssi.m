%{
用RSSI进行距离估计，
用Total RSSI进行距离估计比较合适，原因是get_total_rss脚本用三天线的RSSI计算Total RSSI，并处理了AGC - 44
三天线数据进行测距也不稳定，因为没有进行AGC处理
d = squeeze(dbinv(rssiData(1, :, :)) + dbinv(rssiData(2, :, :)) +dbinv(rssiData(3, :, :)));
rssi_mag = db(d, 'pow') - 44 - csiAgcs;
%}
%%
filePath = 'F:\netlink\training_distance\';
dirInfo = dir(fullfile(filePath, '*.dat'));
fileList = {dirInfo.name}.'; % fileList是一个cell数组
npkgs = 100;
rssiData = zeros(3, npkgs, length(fileList));
rssiTotal = zeros(npkgs, length(fileList));
csiAgcs = zeros(npkgs, length(fileList));
%%
for indFile = 1:length(fileList)  % for 每一个 .dat 文件
    rssi = zeros(3, npkgs);
    totalR = zeros(1, npkgs);
    csiAgc = zeros(1, npkgs);
    csi_trace = read_bf_file([filePath, fileList{indFile}]);
    for indPkg = 1:npkgs % 对每一个csi_trace, 最后的到一个 3 * numOfComp * npkgs的矩阵
        csi_entry = csi_trace{indPkg};
        %% rssi a b c 
        rssia = csi_entry.rssi_a;
        rssib = csi_entry.rssi_b;
        rssic = csi_entry.rssi_c; % 这里减去或者不减去 AGC 情况大不一样 ！！！！！！！！！！！！！！！！！！！！！！
%         rssia = csi_entry.rssi_a - csi_entry.agc;
%         rssib = csi_entry.rssi_b - csi_entry.agc;
%         rssic = csi_entry.rssi_c - csi_entry.agc;
        rssi(:, indPkg) = [rssia; rssib; rssic];
        %% Total rssi
        totalR(indPkg) = get_total_rss(csi_entry);
        %% AGC
        csiAgc(indPkg) = csi_entry.agc;
    end
   rssiData(:, :, indFile) = rssi;
   rssiTotal(:, indFile) = totalR.';
   csiAgcs(:, indFile) = csiAgc.';
end
%% Total Rss 随位置不同变化规律
xdata = [1: .5: 4.5];
PLOT_TOTAL_RSS = 0;
if PLOT_TOTAL_RSS
    figure('Name', 'Total Rssi ');
    boxplot(rssiTotal, xdata); grid on; title('Total Rssi');
end
%{
能量取对数，得到的结果就是线性的关系，rssiTotal是取对数之后的结果是线性的，
dbinv(rssiTotal)是能量的形式，不是线性的关系的
%}
%% Total Rss 能量形式随位置不同的变化规律
PLOT_TOTAL_PWR = 0;
if PLOT_TOTAL_PWR
    figure('Name', 'Total Rssi PWR ');
    boxplot(dbinv(rssiTotal), xdata); grid on; title('Total Rssi PWR');
end
%% 用rssia、rssib、rssic平均估计距离和get_total_rss效果一样
PLOT_AVG = 0;
if PLOT_AVG
    figure('Name', 'Average RSS a b c');
    rssi_Pwr = dbinv(rssiData);
    sumCsi_Pwr = squeeze(sum(rssi_Pwr, 1));
    dbRssiOut = db(sumCsi_Pwr, 'pow') - 44 - csiAgcs;
    boxplot(dbRssiOut, xdata); grid on; title('用rssia、rssib、rssic平均估计距离和get_total_rss效果一样');
end
%% AGC随不同位置变化趋势
PLOT_AGC = 0;
if PLOT_AGC
    figure('Name', 'AGC随距离变化');
    subplot(211); boxplot(csiAgcs, xdata); grid on; title(' AGC随距离变化');
    subplot(212); plot(xdata, csiAgcs.'); hold on; title(' AGC随距离变化');
end
%% 3天线数据分别进行处理
PLOT_EACH_ANTENNA = 0;
if PLOT_EACH_ANTENNA
    figure('Name', 'CSI with 3 antenna');
    rssia = squeeze(rssiData(1, :, :));
    rssia_Pwr = dbinv(rssia);
    rssiaOut = db(rssia_Pwr, 'pow') - 44 - csiAgcs;
    %%
   	rssib = squeeze(rssiData(2, :, :));
    rssib_Pwr = dbinv(rssib);
    rssibOut = db(rssib_Pwr, 'pow') - 44 - csiAgcs;
    %%
    rssic = squeeze(rssiData(3, :, :));
    rssic_Pwr = dbinv(rssic);
    rssicOut = db(rssic_Pwr, 'pow') - 44 - csiAgcs;
    %%
    avgRssiOut = (rssiaOut + rssibOut + rssicOut) / 3;
    %%
	subplot(221); boxplot(rssiaOut, xdata); grid on; title('ANT 1 RSS');
	subplot(222); boxplot(rssibOut, xdata); grid on; title('ANT 2 RSS');
	subplot(223); boxplot(rssicOut, xdata); grid on; title('ANT 3 RSS');
    subplot(224); boxplot(avgRssiOut, xdata); grid on; title('average ANT RSS');
end
%% 三天线的rssi，没有处理AGC
PLOT_EACH_ANTENNA_WITHOUT_AGC = 0;
if PLOT_EACH_ANTENNA_WITHOUT_AGC 
    figure('Name', 'CSI with 3 antenna without');
    subplot(221); boxplot(squeeze(rssiData(1, :, :)), xdata); grid on; title('ANT 1');
    subplot(222);  boxplot(squeeze(rssiData(2, :, :)), xdata); grid on; title('ANT 2');
    subplot(223);  boxplot(squeeze(rssiData(3, :, :)), xdata); grid on; title('ANT 3');
    avgRssData = squeeze(mean(rssiData, 1));
    subplot(224); boxplot(avgRssData, xdata); grid on; title('average ANT RSS');
end




   