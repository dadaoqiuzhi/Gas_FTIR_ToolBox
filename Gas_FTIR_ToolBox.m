%Gas_FTIR_ToolBox
%红外气体池测得的气体产物含量数据分析，特定组分已知总压、温度、峰面积计算浓度
%version 1, 20230809
%刘强，核物理与化学研究所210室，forliubinqiang@163.com,15828636974
clear
close all
disp('##################################################################################################################################')
disp('欢迎使用本程序--by 刘强@中国工程物理研究院核物理与化学研究所，Email:liubinqiang@163.com')
disp('##################################################################################################################################')
fprintf('当前所在目录是%s\n',pwd)
%切换工作路径到打开的文件所在路径
p1 = mfilename('fullpath');
i=strfind(p1,'\');
p1=p1(1:i(end));
cd(p1)
fprintf('切换到Gas_FTIR_ToolBox所在工作路径%s\n',p1)

fprintf('请把实验数据输入到input_data.xlsx文件中,注意第一行气体名应与标准曲线数据一致，各数据单位首行已有提示,气体浓度mol/L\n')
fprintf('标准数据不存在或需要更新请先根据提示更新建立文件\n')

V_GassCell=input('\n请输入红外气体池（包括连接管路）体积（一般是100.09 mL）,单位mL:\n');
fprintf('Gas_FTIR_ToolBox程序正在运行，请等待...\n\n')
%更新建立标准数据
update=input('是否更新或新增标准曲线数据？y/n\n','s');
fprintf('Gas_FTIR_ToolBox程序正在运行，请等待...\n\n')
if strcmpi(update,'y')
    fprintf('请把P_kPa、T_oC、Peak_aera和C_gas数据存入相应的*.txt文件中或新建相关文件，新建文件与input_data文件中命名一致\n')
    update_n=input('请输入更新文件数量：\n');
    for i=1:update_n
        fprintf('请输入第%d个需要更新的文件名,无文件格式后缀，如CO2或N2O：\n',i);
        update_file=input('','s');
        update_file=upper(update_file);
        stad_file=update_file;
        update_file=strcat(update_file,'_update.txt');
        temp_data=load(update_file);%载入更新文件
        temp_data(isnan(temp_data(:,:)),:)=[];
        update_mode=input('更新模式编号选择：1.追加数据 2.全部替换更新 3.新建标准曲线数据\n');
        if update_mode==1
            std_update=load(strcat(stad_file,'.mat'));
            val_names=fieldnames(std_update);
            std_update_data=getfield(std_update,val_names{1});
            std_update_data(size(std_update_data,1)+1:size(std_update_data,1)+size(temp_data,1),:)=num2cell(temp_data(1:end,:));
            Variables={stad_file};
            eval([Variables{1},'=std_update_data',';']);%赋值
            save(strcat(stad_file,'.mat'),stad_file);
        elseif update_mode==2
            std_update=load(strcat(stad_file,'.mat'));
            val_names=fieldnames(std_update);
            std_update_data=getfield(std_update,val_names{1});
            std_update_data(2:end,:)=[];%清空数据行
            std_update_data(2:1+size(temp_data,1),:)=num2cell(temp_data(1:end,:));
            Variables={stad_file};
            eval([Variables{1},'=std_update_data',';']);%赋值
            save(strcat(stad_file,'.mat'),stad_file);
        elseif update_mode==3
            std_update_data={};
            std_update_data(1,:)={'P_kPa','T_oC','Peak_Aera_au','C_gas'};
            std_update_data(2:1+size(temp_data,1),:)=num2cell(temp_data(1:end,:));
            eval([stad_file,'=std_update_data',';']);%赋值
            save(strcat(stad_file,'.mat'),stad_file);
        else
            error('更新模式选择错误，请检查输入！')
        end
    end
    fprintf('标准曲线数据更新完毕\n') 
else
    fprintf('不更新标准曲线数据\n')
end

%读入待求解数据
[ndata, text,alldata]=xlsread('input_data.xlsx','data');
%ndata(isnan(ndata(:,:)),:)=[];%后面每列单独处理
if numel(ndata(isnan(ndata)))
    warning('input_data中存在NaN数据，被转化为0，请检查输入！')
    fprintf('\n')
    ndata(find(isnan(ndata)==1))=0;
end

%检查标准数据存在否
path=pwd;
std_file = dir(fullfile(path,'*.mat'));
std_file_name = {std_file.name}';
for i=4:size(text,2)
    if ~ismember(strcat(upper(text(i)),'.mat'),std_file_name)
        fprintf('input_data中第%d列数据首行%s指定的标准数据%s.mat不存在，请检查！\n',i,text{1,i},upper(text{1,i}))
        error('缺乏标准数据，请检查输入或者更新/建立标准数据%s.mat',upper(text{1,i}))
    end
end

%数据处理方式
fprintf('请输入数据处理方式编号：1.双变量函数c_gas=f(P_Pa/T_K,Peak_aera) 2.三变量函数c_gas=f(P_Pa,T_K,Peak_aera)\n')
data_method=input('');
fprintf('Gas_FTIR_ToolBox程序正在运行，请等待...\n\n')
if data_method==1
    fprintf('请选择c_gas插值方法编号：1.griddata方法 2.scatteredInterpolant方法\n')
    data_interp1=input('');
    if data_interp1==1
        fprintf('标准数据三维格点对应的c_gas插值方法为griddata插入法\n')
        fprintf('请进一步指定griddata方法采用的插值方法：1.linear 2.nearest 3.natural 4.cubic 5.v4\n');
        data_interp2=input('');
        if data_interp2==1
            data_interp2='linear';
        elseif data_interp2==2
            data_interp2='nearest';
        elseif data_interp2==3
            data_interp2='natural';
        elseif data_interp2==4
            data_interp2='cubic';
        elseif data_interp2==5
            data_interp2='v4';
        end
        nan_ans=input('如果标准曲线格点插值出现NaN，是否转化为0？转化为0影响三维展示效果，但一般不影响求解位置数据y/n：\n','s');
    elseif data_interp1==2
        fprintf('采用scatteredInterpolant方法\n')
    else
        error('非法的c_gas插值方法编号输入，请检查！')
    end
end
if data_method==2 || (data_method==1 && data_interp1==2)
    fprintf('采用scatteredInterpolant方法计算待求数据\n')
    fprintf('请指定scatteredInterpolant方法采用的内插值方法：1.linear 2.nearest 3.natural\n');
    data_interp2=input('');
    if data_interp2==1
        data_interp2='linear';
    elseif data_interp2==2
        data_interp2='nearest';
    elseif data_interp2==3
        data_interp2='natural';
    end
    fprintf('请指定scatteredInterpolant方法采用的外插值方法：1.linear 2.nearest 3.none\n')
    data_interp3=input('');
    if data_interp3==1
        data_interp3='linear';
    elseif data_interp3==2
        data_interp3='nearest';
    elseif data_interp3==3
        data_interp3='none';
    end
end
if ~ismember(data_method,[1,2])
    error('非法的数据处理方式编号输入，请检查！')
end
fprintf('Gas_FTIR_ToolBox程序正在运行，请等待...\n\n')

c_gas_target=[];
c_gas_target2=[];
c_gas_target3=[];
for i=4:size(ndata,2)
    
    %导入标准数据
    std_data=load(upper(text{i}));
    val_names=fieldnames(std_data);
    std_data=getfield(std_data,val_names{1});
    std_data_copy=cell2mat(std_data(2:end,:));
    std_data_copy=unique(std_data_copy,'rows');
    fprintf('标准数据%s导入完毕\n',strcat(val_names{1},'.mat'))
    
    if data_method==1 && data_interp1==1
        %处理标准数据并作图
        P_divid_T=std_data_copy(:,1)*1000./(std_data_copy(:,2)+273.15);
        Peak_aera=std_data_copy(:,3);
        C_gas=std_data_copy(:,4);
        std_data_copy=[P_divid_T,Peak_aera,C_gas];
        %当P_divid_T（0-500）或Peak_aera（0-500）为0时，C_gas必须为0，适当插入一些边界值
        fprintf('适量插入边界c_gas为0的值\n')
        x=[0:50:500]';
        y=0*x;z=y;
        xyz=[x,y,z];
        std_data_copy=[std_data_copy;xyz];
        xyz=[y,x,z];
        std_data_copy=[std_data_copy;xyz];
        %扩充后标准曲线排序便于取三维格点
        temp_data=sortrows([std_data_copy(:,1),std_data_copy(:,2),std_data_copy(:,3)],[1 2],{'ascend' 'ascend'});
        temp_data=unique(temp_data,'rows');
        %plot3(temp_data(:,1),temp_data(:,2),temp_data(:,3),'-o','Color','b','MarkerSize',10,'MarkerFaceColor','#D9FFFF','LineWidth',1)
        [xq,yq]=meshgrid(sortrows(unique(temp_data(:,1))),sortrows(unique(temp_data(:,2))));%取标准数据格点
        zq=griddata(temp_data(:,1),temp_data(:,2),temp_data(:,3),xq,yq,data_interp2);%标准数据三维格点插值
        
        if strcmpi(nan_ans,'y')
            if ismember(1,isnan(zq))
                warning('标准数据三维格点插值存在NaN数据，替换为0')
                msgbox({'标准数据三维格点插值存在NaN数据，替换为0';'添加的边界值一般不影响数据分析，请检查结果'},'Warning');
                fprintf('\n请检查结果，建议选择其他插值方法对比结果!\n')
                zq(find(isnan(zq)==1))=0;
            end
        end
        fprintf('标准数据三维格点c_gas插值完成\n')
        figure(2*(i-3)-1)
        % mesh(xq,yq,zq,'FaceAlpha',0.5,'FaceColor','interp','EdgeColor','interp');colorbar
        surf(xq,yq,zq,'FaceAlpha',0.5,'FaceColor','interp','EdgeColor','interp');colorbar %标准数据插值格点取面
        xlabel('P-kPa/T-K');
        ylabel('Peak-aera');
        zlabel('c-gas');
        title_name=strcat('Gas concentration of',{32},text{i});%空格表示为{32}
        title_name=strrep(title_name,'_','-');
        title(title_name);
        legend(strcat('std-',strrep(text{i},'_','-')));
        
        %写三维标准数据格点数据
        filename=strcat('std-',text{i},'-x.txt');
        fid=fopen(filename,'w+');
        for ii=1:size(xq,1)
            for jj=1:size(xq,2)
                fprintf(fid,'%10.5f ',xq(ii,jj));
            end
        end
        fclose(fid);
        filename=strcat('std-',text{i},'-y.txt');
        fid=fopen(filename,'w+');
        for ii=1:size(yq,1)
            for jj=1:size(yq,2)
                fprintf(fid,'%10.5f ',yq(ii,jj));
            end
        end
        fclose(fid);
        filename=strcat('std-',text{i},'-z.txt');
        fid=fopen(filename,'w+');
        for ii=1:size(zq,1)
            for jj=1:size(zq,2)
                fprintf(fid,'%12.10f ',zq(ii,jj));
            end
        end
        fclose(fid);

        fprintf('标准数据%s插值数据导出完成（std-*-x/y/z.txt）\n',text{i})
        
        %实验待求数据插值
        fprintf('请选择待求解数据三维格点用interp2方法对c_gas计算的插值方法编号：1.linear 2.nearest 3.makima 4.spline\n')
        data_interp2=input('');
        if data_interp2==1
            data_interp2='linear';
        elseif data_interp2==2
            data_interp2='nearest';
        elseif data_interp2==3
            data_interp2='makima';
        elseif data_interp2==4
            data_interp2='spline';
        end
        c_gas_target=[];
        data_target=[ndata(:,1)*1000./(ndata(:,2)+273.15),ndata(:,i),];
        data_target_copy=data_target;
        %注意数据顺序可能被排序打乱了！
        data_target=sortrows([data_target(:,1),data_target(:,2)],[1 2],{'ascend' 'ascend'});
        %[C,ia] = unique(data_target(:,1));
        %data_target=data_target(ia,:);%去掉第一列重复值，等价于[data_target,ia] = unique(data_target(:,1));
        %取待求数据组成的数据格点，注意数据顺序可能被排序打乱了！
        [data_target_x,data_target_y]=meshgrid(sortrows(unique(data_target(:,1))),sortrows(unique(data_target(:,2))));
        c_gas_target=interp2(xq,yq,zq,data_target_x,data_target_y,data_interp2);
        %提取待求点数据
        for j=1:size(data_target,1)
            for k=1:size(data_target_x,2)
                if data_target(j,1)==data_target_x(1,k)
                    for jj=1:size(data_target_y,1)
                        if data_target_y(jj,1)==data_target(j,2)
                            data_target(j,3)=c_gas_target(jj,k);
                        end
                    end
                end
            end
        end
        %将数据按照input_data.xlsx输入文件排序
        for j=1:size(data_target_copy,1)
            for k=1:size(data_target,1)
                if sum(data_target_copy(j,1:2)==data_target(k,1:2))==2
                    data_target_copy(j,3)=data_target(k,3);%按照原来顺序赋值
                end
            end
        end
        c_gas_target2(:,i-3)=data_target_copy(:,3);%求解数据矩阵，mol/L
        c_gas_target3(:,i-3)=c_gas_target2(:,i-3).*(ndata(:,3)+V_GassCell)/1000;%求解气体mol数矩阵
        fprintf('第%d组数据%s求解完成\n',i-3,text{i})
        
        
        %只叠加画画待求数据
        figure(2*(i-3))
        % mesh(xq,yq,zq,'FaceAlpha',0.5,'FaceColor','interp','EdgeColor','interp');colorbar
        surf(xq,yq,zq,'FaceAlpha',0.5,'FaceColor','interp','EdgeColor','interp');colorbar
        fprintf('标准数据三维格点c_gas插值完成\n')
        hold on
        scatter3(data_target_copy(:,1),data_target_copy(:,2),data_target_copy(:,3),'MarkerEdgeColor','k','MarkerFaceColor','r')
        view(-45,30);
        xlabel('P-kPa/T-K');
        ylabel('Peak-aera');
        zlabel('c-gas');
        zlim([0 max(data_target_copy(:,3))*1.5])
        title_name=strcat('Gas concentration of',{32},text{i});%空格表示为{32}
        title_name=strrep(title_name,'_','-');
        title(title_name);
        legend(strcat('std-',strrep(text{i},'_','-')),strcat('target-',strrep(text{i},'_','-')));
        fprintf('只叠加显示待求数据散点，其余待解析数据格点划分产生的多余格点数据不显示\n')
        %待求数据格点插值所有数据
        %plot3(data_target_x,data_target_y,c_gas_target,'-o','Color','r','MarkerSize',10,'MarkerFaceColor','#D9FFFF','LineWidth',1)
        hold off
        
        
        
    elseif (data_method==1 && data_interp1==2) || data_method==2
        if data_method==2
            std_data_copy(:,1)=std_data_copy(:,1)*1000;%kPa-->Pa
            std_data_copy(:,2)=std_data_copy(:,2)+273.15;%oC-->K
            %当P_divid_T（0-500）或Peak_aera（0-500）为0时，C_gas必须为0，适当插入一些边界值
            fprintf('适量插入边界c_gas为0的值\n')
            x=logspace(0,6,15)';x=[0;x];%P
            y=[273:(200/(size(x,1)-1)):473]';%T
            z=[0:(500/(size(x,1)-1)):500]';%peak_aera
            zz=x*0;%c_gas
            xyz=[zz,y,z,zz];
            std_data_copy=[std_data_copy;xyz];
            xyz=[x,y,zz,zz];
            std_data_copy=[std_data_copy;xyz];
            %扩充后标准曲线排序便于取三维格点
            temp_data=sortrows([std_data_copy(:,1),std_data_copy(:,2),std_data_copy(:,3),std_data_copy(:,4)],[1 2 3],{'ascend' 'ascend' 'ascend'});
            temp_data=unique(temp_data,'rows');
            %[xq,yq,zq]=meshgrid(sortrows(unique(temp_data(:,1))),sortrows(unique(temp_data(:,2))),sortrows(unique(temp_data(:,3))));%取标准数据格点
            %zzq=griddata(temp_data(:,1),temp_data(:,2),temp_data(:,3),temp_data(:,4),xq,yq,zq,data_interp2);
            
            data_target_F=scatteredInterpolant(temp_data(:,1),temp_data(:,2),temp_data(:,3),temp_data(:,4),data_interp2,data_interp3);%扩充版标准数据散点数据插值对象
            %求解待求数据
            data_target=[ndata(:,1)*1000,ndata(:,2)+273.15,ndata(:,i)];
            c_gas_target2(:,i-3)=data_target_F(data_target(:,1),data_target(:,2),data_target(:,3));%求解浓度矩阵
            c_gas_target3(:,i-3)=c_gas_target2(:,i-3).*(ndata(:,3)+V_GassCell)/1000;%求解气体mol数矩阵
            fprintf('第%d组数据%s求解完成\n',i-3,text{i})
            
        elseif data_method==1 && data_interp1==2
            P_divid_T=std_data_copy(:,1)*1000./(std_data_copy(:,2)+273.15);
            Peak_aera=std_data_copy(:,3);
            C_gas=std_data_copy(:,4);
            std_data_copy=[P_divid_T,Peak_aera,C_gas];
            %当P_divid_T（0-500）或Peak_aera（0-500）为0时，C_gas必须为0，适当插入一些边界值
            fprintf('适量插入边界c_gas为0的值\n')
            x=[0:50:500]';
            y=0*x;z=y;
            xyz=[x,y,z];
            std_data_copy=[std_data_copy;xyz];
            xyz=[y,x,z];
            std_data_copy=[std_data_copy;xyz];
            %扩充后标准曲线排序便于取三维格点
            temp_data=sortrows([std_data_copy(:,1),std_data_copy(:,2),std_data_copy(:,3)],[1 2],{'ascend' 'ascend'});
            temp_data=unique(temp_data,'rows');
            data_target_F=scatteredInterpolant(temp_data(:,1),temp_data(:,2),temp_data(:,3),data_interp2,data_interp3);%扩充版标准数据散点数据插值对象
            %求解待求数据
            data_target=[ndata(:,1)*1000./(ndata(:,2)+273.15),ndata(:,i)];
            c_gas_target2(:,i-3)=data_target_F(data_target(:,1),data_target(:,2));%求解浓度矩阵
            c_gas_target3(:,i-3)=c_gas_target2(:,i-3).*(ndata(:,3)+V_GassCell)/1000;%求解气体mol数矩阵
            fprintf('第%d组数据%s求解完成\n',i-3,text{i})
            
            figure(i-3)
            scatter3(temp_data(:,1),temp_data(:,2),temp_data(:,3),'MarkerEdgeColor','k','MarkerFaceColor',[0 .75 .75]);
            hold on
            xlabel('P-kPa/T-K');
            ylabel('Peak-aera');
            zlabel('c-gas');
            title_name=strcat('Gas concentration of',{32},text{i});%空格表示为{32}
            title_name=strrep(title_name,'_','-');
            title(title_name);
            scatter3(data_target(:,1),data_target(:,2),c_gas_target2(:,i-3),'MarkerEdgeColor','k','MarkerFaceColor','r');
            legend(strcat('std-',strrep(text{i},'_','-')),strcat('target-',strrep(text{i},'_','-')));
            zlim([0 max(c_gas_target2(:,i-3))*1.5])
            hold off
            
            save(strcat('std-',text{i},'-xyz.txt'),'temp_data','-ascii')
            fprintf('标准数据%s插值数据导出完成（std-*-xyz.txt）\n',text{i})
            
        end
        
    else
        error('非法数据处理方式编号输入，请检查！')
    end
end

data_target2={};
data_target2(1,:)=text(1,4:end);
data_target2(2:1+size(c_gas_target2,1),:)=num2cell(c_gas_target2);

filename='Target_data_c.txt';
fid=fopen(filename,'w+');
kk=2;
for ii=1:size(data_target2,1)
    if kk>ii && ii>1
        fprintf(fid,'\n');
    end
    for jj=1:size(data_target2,2)
        if ii==1
            fprintf(fid,'%13s  ',data_target2{ii,jj});
            kk=kk+1;
        else
            fprintf(fid,'%13.11f  ',data_target2{ii,jj});
            kk=kk+1;
        end
    end
end
fclose(fid);
writecell(data_target2,'Target_data_c.xlsx');
fprintf('待求解气体的浓度数据储存在data_target2元胞中,成功导出到Target_data_c文件中（txt和xlsx）\n')

data_target3={};
data_target3(1,:)=text(1,4:end);
data_target3(2:1+size(c_gas_target3,1),:)=num2cell(c_gas_target3);

filename='Target_data_n.txt';
fid=fopen(filename,'w+');
kk=2;
for ii=1:size(data_target3,1)
    if kk>ii && ii>1
        fprintf(fid,'\n');
    end
    for jj=1:size(data_target3,2)
        if ii==1
            fprintf(fid,'%13s  ',data_target3{ii,jj});
            kk=kk+1;
        else
            fprintf(fid,'%13.11f  ',data_target3{ii,jj});
            kk=kk+1;
        end
    end
end
fclose(fid);
writecell(data_target3,'Target_data_n.xlsx');
fprintf('待求解气体的mol数据储存在data_target3元胞中,成功导出到Target_data_n文件中（txt和xlsx）\n')
fprintf('Gas_FTIR_ToolBox程序运行正常结束\n\n')

% clear data_interp2 data_interp3 data_method data_target_F fid filename i ii j k jj kk m path std_file std_file_name update
% clear V_GassCell val_names x y z xq yq zq zzq xyz title_name Peak_aera P_divid_T data_target_x data_target_y data_interp1 
% clear data_interp2 data_interp3 nan_ans


