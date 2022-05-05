function [varargout]=ww3map(s,rng,cmap,varargin)
%WW3MAP    Maps WaveWatch III hindcast data
%
%    Usage:    ww3map('file')
%              ww3map('file',rng)
%              ww3map('file',rng,cmap)
%              ww3map('file',rng,cmap,'mmap_opt1',mmap_val1,...)
%              ww3map(s,...)
%              ax=ww3map(...)
%
%    Description:
%     WW3MAP('FILE') maps the WaveWatch III hindcast data contained in the
%     GRiB or GRiB2 file FILE averaged across all the records (basically
%     showing the average for the time span of the data in the GRiB file).
%     One map per data type (this only matters for wind which means the u/v
%     components are drawn seperately).  If no filename is given a GUI is
%     presented for the user to select a WW3 hindcast file.
%
%     WW3MAP('FILE',RNG) sets the colormap limits of the data. The default
%     is dependent on the datatype: [0 15] for significant wave heights and
%     wind speed, [0 20] for wave periods, [0 360] for wave & wind
%     direction, & [-15 15] for u & v wind components.
%
%     WW3MAP('FILE',RNG,CMAP) alters the colormap to CMAP.  The default is
%     HSV for wave & wind direction and FIRE for everything else.  The FIRE
%     colormap is adjusted to best match the background color.
%
%     WW3MAP('FILE',RNG,CMAP,'MMAP_OPT1',MMAP_VAL1,...) passes additional
%     options on to MMAP to alter the map.
%
%     WW3MAP(S,...) plots the WaveWatch III data contained in the
%     structure S created by WW3STRUCT.  The plots average the data across
%     all records for each data type.
%
%     AX=WW3MAP(...) returns the axes drawn in.
%
%    Notes:
%     - Requires that the njtbx toolbox is installed!
%     - Passing the 'parent' MMAP option requires as many axes as
%       datatypes.  This only matters for wind data.
%
%    Examples:
%     % Read the first record of a NOAA WW3 grib file and map it:
%     s=ww3struct('nww3.hs.200607.grb',1);
%     ax=ww3map(s);
%
%    See also: WW3STRUCT, WW3MAPMOV, PLOTWW3, PLOTWW3TS, WW3MOV, WW3REC,
%              WW3CAT, WW3UV2SA, WW3BAZ2AZ

%     Version History:
%        May   5, 2012 - initial version
%        Sep.  5, 2012 - set nan=0 for ice
%        Oct.  5, 2012 - no file bugfix for rng
%        Aug. 27, 2013 - use mmap image option
%        Jan. 15, 2014 - updated See also list
%        Jan. 16, 2014 - minor doc fix
%        Feb.  5, 2014 - doc & comment fixes, proper handling of direction
%                        data and nans for ice/land, don't color nans,
%                        colormap input, smart rng/cmap defaults
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Feb.  5, 2014 at 00:40 GMT

% todo:

% check ww3 input
if(nargin==0) % gui selection of grib file
    % this does the gui & checks file is valid
    s=ww3struct();
    if(~isscalar(s))
        error('seizmo:ww3map:badWW3',...
            'WW3MAP can only handle 1 file!');
    end
elseif(isstruct(s))
    valid={'path' 'name' 'description' 'units' 'data' ...
        'lat' 'lon' 'time' 'latstep' 'lonstep' 'timestep'};
    if(~isscalar(s) || any(~ismember(valid,fieldnames(s))))
        error('seizmo:ww3map:badWW3',...
            'S must be a scalar struct as generated by WW3STRUCT!');
    end
elseif(ischar(s)) % filename given
    % this checks file is valid
    s=ww3struct(s);
else
    error('seizmo:ww3map:badWW3',...
        'FILE must be a string!');
end

% default/check color limits
if(nargin<2 || isempty(rng)); rng=[nan nan]; end
if(~isreal(rng) || ~isequal(size(rng),[1 2]) || rng(1)>rng(2))
    error('seizmo:ww3map:badRNG',...
        'RNG must be a real-valued 2 element vector as [low high]!');
end

% default/check colormap input
defcmap=false;
if(nargin<3 || isempty(cmap)); cmap='default'; defcmap=true; end
if((isnumeric(cmap) && isreal(cmap) ...
        && (ndims(cmap)~=2 || size(cmap,2)~=3 ...
        || ~all(cmap(:)>=0 & cmap(:)<=1))) || (ischar(cmap) ...
        && (ndims(cmap)~=2 || size(cmap,1)~=1)))
    error('seizmo:ww3map:badCMAP',...
        ['COLORMAP must be a colormap function as\n'...
        'a string or a Nx3 RGB triplet array!']);
end

% check options are strings
if(~iscellstr(varargin(1:2:end)))
    error('seizmo:ww3map:badOption',...
        'All Options must be specified with a string!');
end

% check number of axes
ndata=numel(s.data);
defax=cell(ndata,1);
for i=1:2:numel(varargin)
    switch lower(varargin{i})
        case {'axis' 'ax' 'a' 'parent' 'pa' 'par'}
            if(numel(varargin{i+1})~=ndata)
                error('seizmo:ww3map:badAX',...
                    'Number of axes must equal the number of datatypes!');
            else
                defax=num2cell(varargin{i+1});
            end
    end
end

% a couple mmap default changes
% - use min/max of lat/lon as the map boundary
% - do not show land/ocean
varargin=[{'po' {'lat' [min(s.lat) max(s.lat)] ...
    'lon' [min(s.lon) max(s.lon)]} 'l' false 'o' false} varargin];

% time string
if(numel(s.time)==1)
    tstring=datestr(s.time,31);
else % >1
    tstring=[datestr(min(s.time),31) ' to ' datestr(max(s.time),31)];
end

% loop over data types
ax=nan(ndata,1);
for i=1:ndata
    % average data handling ice/land (nans) & direction
    if(size(s.data{i},3)>1)
        if(isequal(s.units{i},'degrees'))
            s.data{i}=azmean(s.data{i},3);
            s.data{i}(s.data{i}<0)=s.data{i}(s.data{i}<0)+360;
        else
            s.data{i}=nanmean(s.data{i},3);
        end
    end
    
    % draw map, skip coloring on nans (land/ice) & set colormap limits
    ax(i)=mmap('image',{s.lat s.lon s.data{i}.'},...
        varargin{:},'parent',defax{i});
    set(findobj(ax(i),'tag','m_pcolor'),...
        'alphadata',double(~isnan(s.data{i}([1:end end],[1:end end]).')));
    if(all(isnan(rng)))
        if(isequal(s.units{i},'degrees'))
            rng0=[0 360];
        elseif(isequal(s.units{i},'s'))
            rng0=[0 20];
        elseif(any(strcmp(s.description{i},{'U-component of wind' ...
                'V-component of wind' 'u wind' 'v wind'})))
            rng0=[-15 15];
        else
            rng0=[0 15];
        end
    else
        rng0=rng;
    end
    set(ax(i),'clim',rng0);
    
    % extract color
    bg=get(get(ax(i),'parent'),'color');
    fg=get(findobj(ax(i),'tag','m_grid_box'),'color');
    
    % labeling
    title(ax(i),...
        {'NOAA WaveWatch III Hindcast' s.description{i} tstring},...
        'color',fg);
    
    % set colormap
    if(defcmap)
        if(isequal(s.units{i},'degrees'))
            colormap(ax(i),hsv);
        elseif(strcmp(bg,'w') || isequal(bg,[1 1 1]))
            colormap(ax(i),flipud(fire));
        else
            colormap(ax(i),fire);
        end
    else
        colormap(ax(i),cmap);
    end
    
    % colorbar
    c=colorbar('eastoutside','peer',ax(i),'xcolor',fg,'ycolor',fg);
    xlabel(c,s.units{i},'color',fg);
end

% output if wanted
set(ax,'tag','ww3map');
if(nargout); varargout{1}=ax; end

end