% Citibike nyc data analysis
% Alessandro Rizzo

% I have imported the data with the matlab data importer

% transform the start time in number 

ltd=length(tripduration); 
startvec=zeros(ltd,6);
stopvec=zeros(ltd,6);

for k=1:ltd
    j=2;
    v=char(starttime(k));
    v1=[];
    while(v(j)~='/')
        v1=[v1 v(j)];
        j=j+1;
    end
    startmon=str2num(v1);
    
    j=j+1;
    v1=[];
    while(v(j)~='/')
        v1=[v1 v(j)];
        j=j+1;
    end
    startday=str2num(v1);
    
    startyear=str2num(v(j+1:j+4));
    starthr=str2num(v(j+6:j+7));
    startmin=str2num(v(j+9:j+10));
    startsec=str2num(v(j+12:j+13));
    
    startvec(k,:)=[startyear startmon startday starthr startmin startsec];
end
    
startvecnum=datenum(startvec);

for k=1:ltd
    j=2;
    v=char(stoptime(k));
    v1=[];
    while(v(j)~='/')
        v1=[v1 v(j)];
        j=j+1;
    end
    stopmon=str2num(v1);
    
    j=j+1;
    v1=[];
    while(v(j)~='/')
        v1=[v1 v(j)];
        j=j+1;
    end
    stopday=str2num(v1);
    
    stopyear=str2num(v(j+1:j+4));
    stophr=str2num(v(j+6:j+7));
    stopmin=str2num(v(j+9:j+10));
    stopsec=str2num(v(j+12:j+13));
    
    stopvec(k,:)=[stopyear stopmon stopday stophr stopmin stopsec];
end
    
stopvecnum=datenum(stopvec);


% clean the data: eliminate trips that last more than two hours

bikeidc=[];
endstatidc=[];
endstatlatc=[];
endstatlongc=[];
startstatidc=[];
startstatlatc=[];
startstatlongc=[];
tripdurc=[];
startvecnumc=[];
stopvecnumc=[];

for k=1:ltd
    if (tripduration(k) < 7200)
        tripdurc = [tripdurc ; tripduration(k)];
        bikeidc = [bikeidc ; bikeid(k)];
        endstatidc = [endstatidc ; endstationid(k)]; 
        endstatlatc = [endstatlatc ; endstationlatitude(k)];
        endstatlongc = [endstatlongc ; endstationlongitude(k)];
        startstatidc = [startstatidc ; startstationid(k)]; 
        startstatlatc = [startstatlatc ; startstationlatitude(k)];
        startstatlongc = [startstatlongc ; startstationlongitude(k)];
        startvecnumc = [startvecnumc ; startvecnum(k)];
        stopvecnumc = [stopvecnumc ; stopvecnum(k)];
    end
    
end

ltdc=length(tripdurc); %size of clean data
lstatactivity=6*24*35;

statactivity=zeros(length(stationids),lstatactivity);
deltat=(1/(24*60))*10; %10 mins in day units
start=startvecnumc(1);

for k=1:ltdc
    j=find(stationids==startstatidc(k));
    
    if ~(isempty(j))
        timeindex=floor((startvecnumc(k)-start)/deltat)+1;
        statactivity(j,timeindex)=statactivity(j,timeindex)-1; %departure

        j=find(stationids==endstatidc(k));
        timeindex=floor((stopvecnumc(k)-start)/deltat)+1;
        statactivity(j,timeindex)=statactivity(j,timeindex)+1; %arrival
    end
    
    
end

%evaluate instantaneous conditions 

low=min(min(statactivity));
[xm,ym] = find(statactivity==low);
for k=1:length(xm)
    figure;
    plot(statactivity(xm,:));
    v=['Station ',num2str(stationids(xm(k))),' risked to be empty at time ',num2str(ym(k))]; 
    title(v);
    xlabel('Time (Delta T = 10 min)'); 
    ylabel('Bike count from T=0'); 
    display(v);
end


high=max(max(statactivity));
[xM,yM] = find(statactivity==high);
for k=1:length(xM)
    figure;
    plot(statactivity(xM(k),:));
    v=['Station ',num2str(stationids(xM(k))),' risked to be empty at time ',num2str(yM(k))]; 
    title(v);
    xlabel('Time (Delta T = 10 min)'); 
    ylabel('Bike count from T=0'); 
    display(v);
end

% OR work with the derivatives (change in time)
% we want to know when more than M bikes have been docked/undocked at a 
% station in a time interval T 
% we relate M to the station capacity. In this test, we raise an alarm when
% a M is a third of the station capacity - T is set to one hour = 6 samples

M=floor(stations(:,2)./3);
T=6;

for i=1:length(stationids)
    k=1;
    j=1;
    while((k+T)<=lstatactivity);
        statactivitydiff(i,j)=statactivity(i,k+T)-statactivity(i,k);
        j=j+1;
        k=k+1;
    end
end

stationfullvec=[];
stationemptyvec=[];
stationfulltime=[];
stationemptytime=[];

for i=1:length(stationids)
    [yM]=find(statactivitydiff(i,:)>M(i));
    if ~(isempty(yM))
        figure;
        plot(statactivitydiff(i,:));
        hold on; 
        plot(M(i)*ones(1,length(statactivitydiff)),'r'); 
        hold off
        v=['More than ',num2str(M(i)),' bikes per hour have been docked at station ',num2str(stationids(i))]; 
        title(v);
        xlabel=('Time (Delta T = 10 min)'); 
        ylabel=('Docked/Undocked bikes per hour'); 
        stationfullvec=[stationfullvec ; i];
        stationfulltime=[stationfulltime ; yM(1)]; 
    end
        
        
    [ym]=find(statactivitydiff(i,:)<-M(i));
    if ~(isempty(ym))
        figure;
        plot(statactivitydiff(i,:));
        hold on; 
        plot(-M(i)*ones(1,length(statactivitydiff)),'r'); 
        hold off
        v=['More than ',num2str(M(i)),' bikes per hour have been undocked at station ',num2str(stationids(i))]; 
        title(v);
        xlabel=('Time (Delta T = 10 min)'); 
        ylabel=('Docked/Undocked bikes per hour'); 
        stationemptyvec=[stationemptyvec ; i]; 
        stationemptytime=[stationemptytime ; ym(1)];
    end  
end

        
 % find candidates for the rebalancing
 % compute the matrix of Euclidean distances 
 
     for i=1:length(stationids)
         for j=1:length(stationids)
             stationdist(i,j)=sqrt((latitude(i)-latitude(j))^2+(longitude(i)-longitude(j))^2);
         end
         [distsort,sortidx]=sort(stationdist(i,:),2,'ascend');
         closerstations(i,:)=sortidx;
     end

 % candidate rebalancer for stations that risk to be full
 % I pick the first ten closest stations that tend to be empty at the alarm
 % time
 
 display('one')

     for i=1:length(stationfullvec)
         j=1; 
         k=1;
         while(j<=10 && k<=length(stationids) )
             if(statactivitydiff(closerstations(i,k),stationfulltime(i))<0) 
                 candidate(i,j)=closerstations(i,k); 
                 j=j+1;
             end
             k=k+1; 
         end
     end

display('two')
     
 for i=1:length(stationfullvec)
     figure;
     plot(stationids(candidate(i,:)),statactivitydiff(candidate(i,:),stationfulltime(i)),'*');
     v=['Candidate Rebalancer for Station ',num2str(stationids(stationfullvec(i))),' - Send bikes to the stations in graph'];
     clear title xlabel ylabel
     title(v);
     xlabel('Station ID');
     ylabel('Docked bikes per hour');
 end
 
 % candidate rebalancer for stations that risk to be empty
 % I pick the first ten closest stations that tend to be full at the alarm
 % time
 
 display('three')
 
for i=1:length(stationemptyvec)
         j=1; 
         k=1;
         while(j<=10 && k<=length(stationids))
             if(statactivitydiff(closerstations(i,k),stationemptytime(i))>0) 
                 candidate(i,j)=closerstations(i,k); 
                 j=j+1;
             end
             k=k+1; 
         end
end

display('four')

 for i=1:length(stationemptyvec)
     figure;
     plot(stationids(candidate(i,:)),statactivitydiff(candidate(i,:),stationemptytime(i)),'*');
     v=['Candidate Rebalancer for Station ',num2str(stationids(i)),' - Recall bikes from the stations in graph'];
     clear title xlabel ylabel
     title(v);
     xlabel('Station ID');
     ylabel('Docked bikes per hour');
 end 
 
 
        
        
        
        
        


