function [varargout]=plot_mlocate_ellipsoids(varargin)
%PLOT_MLOCATE_ELLIPSOIDS  Plots MLOCATE confidence ellipsoids
%
%    Usage:    h=plot_mlocate_ellipsoids(file)
%              h=plot_mlocate_ellipsoids(file1,...,fileN)
%
%    Description:
%     H=PLOT_MLOCATE_ELLIPSOIDS(FILE) reads ellisoid location files
%     generated by the program MLOCATE and plots them.  The read format is
%     very strict (see the source code below for details).  If FILE is not
%     given or is empty, a graphical file selection menu is presented.
%
%     H=PLOT_MLOCATE_ELLIPSOIDS(FILE1,...,FILEN) allows plotting multiple
%     MLOCATE ellipsoid files.
%
%    Notes:
%     - Code was originally written by Erica Emry.  I have added
%       documentation and touched it up to make use of SEIZMO.
%
%    Examples:
%     % Plot some ellipsoids (example.ellipse is a test set of ellipsoids
%     % for the Marianas subduction zone - dataset from Erica Emry):
%     plot_mlocate_ellipsoids(which('example.ellipse'))
%
%    See also: ELLIPSOID

%     Version History:
%        Mar.  6, 2009 - initial version (in SEIZMO)
%        Apr. 23, 2009 - works with updated ONEFILELIST
%        Jan. 27, 2010 - allow no input (select files graphically), added
%                        history and documentation, clean up code a bit
%        Feb. 14, 2010 - use ONEFILELIST filterspec global option
%        Apr. 22, 2010 - more credit where credit is due
%        June 24, 2010 - fix no path bug
%        Feb. 11, 2011 - fix axes calls in plotting commands, no inv call
%        Mar.  7, 2011 - minor doc update
%
%     Written by Erica Emry (ericae at wustl dot edu)
%                Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Mar.  7, 2011 at 17:05 GMT

% todo:

% set filterspec appropriately
global SEIZMO
SEIZMO.ONEFILELIST.FILTERSPEC=...
    {'*.ellipse;*.ELLIPSE' 'ELLIPSE Files (*.ellipse,*.ELLIPSE)';
     '*.mlocate;*.MLOCATE' 'MLOCATE Files (*.mlocate,*.MLOCATE)'};

% parse input
files=onefilelist(varargin);

% spawn figure
fh=figure;
ax=axes('parent',fh);
hold(ax,'on');

% colormap
cint=256;
repeatint=100;
cmap=hsv(cint);

% ellipsoid points
npts=8;
npts2=(npts+1)^2;

% how many mlocate files to read in?
zmin=nan; zmax=nan;
for n=1:numel(files)
    % make filename
    filename=[files(n).path filesep files(n).name];
    
    % read in info
    try
        [lat,lon,dep]=textread(filename,...
            '%10.4f%10.4f%10.4f',1,'headerlines',1);
        [years,months,days,hours,minutes,mag,...
            latdev,londev,depdev,...
            xx,xy,xz,xdist,...
            yx,yy,yz,ydist,...
            zx,zy,zz,zdist]=textread(...
            filename,['%4d-%2d-%2d-%2d:%2d-%5.2f\n'...
                           '%8.2f%8.2f%8.2f\n'...
                           '   %10.5f%10.5f%10.5f%10.5f\n'...
                           '   %10.5f%10.5f%10.5f%10.5f\n'...
                           '   %10.5f%10.5f%10.5f%10.5f\n'],...
                           'headerlines',7);
    catch
        warning(lasterror.message)
        error('seizmo:plot_mlocate_ellipsoids',...
            'Had trouble reading ELLIPSE file: %s!',filename);
    end
    
    % loop through each ellipsoid
    nellips=numel(xx);
    for i=1:nellips
        % rotation matrix (to orient ellipsoid)
        v=[xx(i) xy(i) xz(i);
           yx(i) yy(i) yz(i);
           zx(i) zy(i) zz(i)];
        
        % ellipsoid (unoriented)
        [x,y,z]=ellipsoid(0,0,0,xdist(i),ydist(i),zdist(i),npts);
        
        % rotate ellipsoid
        temp=[x(:) y(:) z(:)]/v;
        
        % translate ellipsoid (to centroid reference frame)
        x(:)=temp(:,1)+latdev(i);
        y(:)=temp(:,2)+londev(i);
        z(:)=temp(:,3)+depdev(i);
        clear temp
        
        % translate ellipsoid (to WGS-84 ellipsoid Earth reference frame)
        % km north and east ==> distance & azimuth (this could cause error)
        % lat, lon, distance, bearing ==> lat, lon
        [x(:),y(:)]=vincentyfwd(lat(ones(npts2,1)),lon(ones(npts2,1)),...
            sqrt(x(:).^2+y(:).^2),-atan2(x(:),y(:))*180/pi+90);
        z=dep+z;
        
        % check for minimum/maximum
        zmin=min([zmin; z(:)]);
        zmax=max([zmax; z(:)]);
        
        % draw ellipsoid (cycle ellipsoid coloring every 100km)
        surf(ax,x,y,z,'facecolor',...
            cmap(1+mod(round(cint*(dep+depdev(i))/repeatint),cint),:),...
            'edgecolor','none');
    end
end
hold(ax,'off');

% setup colormap used
%zmin=round(zmin); zmax=round(zmax);
%zminr=fix(zmin/repeatint); zmaxr=fix(zmax/repeatint);
%fmini=1+mod(round(cint*zmin/repeatint),cint);
%fmaxi=1+mod(round(cint*zmax/repeatint),cint);
%cmap=[cmap(fmini:end,:); repmat(cmap,[zmaxr-zminr 1]); cmap(1:fmaxi,:)];
%colormap(ax,cmap);

% universal plotting parameters
%colorbar('location','eastoutside','ydir','reverse','peer',ax);
set(ax,'ZDir','reverse');
set(ax,'YDir','reverse');
xlabel(ax,'Latitude (deg)');
ylabel(ax,'Longitude (deg)');
zlabel(ax,'Depth (km)');
box(ax,'on');
view(ax,3);
rotate3d(ax,'on');
axis(ax,'tight','vis3d');
%lighting(ax,'phong');
lighting(ax,'gouraud');
material(ax,'shiny');
light('parent',ax,'Position',[ 1 -1  0],'Style','infinite');
light('parent',ax,'Position',[ 1  1  0],'Style','infinite');
light('parent',ax,'Position',[-1  0  0],'Style','infinite');

if(nargout); varargout{1}=ax; end

end
