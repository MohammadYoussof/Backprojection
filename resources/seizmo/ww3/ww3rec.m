function [s]=ww3rec(s,rec)
%WW3REC    Subset WaveWatch III hindcast data struct by record index
%
%    Usage:    s=ww3rec(s,rec)
%
%    Description:
%     S=WW3REC(S,REC) extracts records REC from the WaveWatch III data
%     contained in the structure S created by WW3STRUCT.
%
%    Notes:
%
%    Examples:
%     % Plot each record of a user-selected gribfile separately:
%     s=ww3struct();
%     for i=1:numel(s.time); plotww3(ww3rec(s,i)); end
%
%    See also: WW3STRUCT, WW3CAT, PLOTWW3, PLOTWW3TS, WW3MOV, WW3MAP,
%              WW3MAPMOV, WW3UV2SA, WW3BAZ2AZ

%     Version History:
%        May   4, 2012 - initial version
%        Jan. 15, 2014 - updated See also list
%        Feb.  5, 2014 - fixed warning id, no error if not scalar
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Feb.  5, 2014 at 00:40 GMT

% todo:

% check nargin
error(nargchk(2,2,nargin));

% check ww3 struct
valid={'path' 'name' 'description' 'units' 'data' ...
    'lat' 'lon' 'time' 'latstep' 'lonstep' 'timestep'};
if(~isstruct(s) || any(~ismember(valid,fieldnames(s))))
    error('seizmo:ww3rec:badWW3',...
        'S must be a struct as generated by WW3STRUCT!');
end

% number of elements
ns=numel(s);

% basic indices checks
if(~isnumeric(rec) || ~isreal(rec) || any(rec)<=0 || any(rec~=fix(rec)))
    error('seizmo:ww3rec:badREC',...
        'REC must be a scalar or vector of indices!');
end
for i=1:ns
    nrecs=numel(s(i).time);
    if(any(rec>nrecs))
        error('seizmo:ww3rec:badREC',...
            ['REC greater than number of records in S(' num2str(i) ')!']);
    end
end

% loop over each struct element
for i=1:ns
    % subset to specified indices
    s(i).time=s(i).time(rec);
    for j=1:numel(s(i).data); s(i).data{j}=s(i).data{j}(:,:,rec); end
end

end