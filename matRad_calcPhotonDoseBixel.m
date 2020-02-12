function dose = matRad_calcPhotonDoseBixel(SAD,machineData,Interp_kernel1,...
                  Interp_kernel2,Interp_kernel3,Interp_kernel4,radDepths,geoDists,...
                  isoLatDistsX,isoLatDistsZ)
% matRad photon dose calculation for an individual bixel
% 
% call
%   dose = matRad_calcPhotonDoseBixel(SAD,Interp_kernel1,...
%                  Interp_kernel2,Interp_kernel3,radDepths,geoDists,...
%                  latDistsX,latDistsZ)
%
% input
%   SAD:                  source to axis distance
%   machineData:          several machine parameters (m, betas, surface dose,...
%                         electron range intensity)
%   Interp_kernel1/2/3/4: kernels for dose calculation
%   radDepths:            radiological depths
%   geoDists:             geometrical distance from virtual photon source
%   isoLatDistsX:         lateral distance in X direction in BEV from central
%                         ray at iso center plane
%   isoLatDistsZ:         lateral distance in Z direction in BEV from central
%                         ray at iso center plane
%
% output
%   dose:   photon dose at specified locations as linear vector
%
% References
%   [1] http://www.ncbi.nlm.nih.gov/pubmed/8497215
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define function_Di
func_Di = @(beta,x) beta/(beta-machineData.m) * (exp(-machineData.m*x) - exp(-beta*x)); 

% Calulate lateral distances using grid interpolation.
lat1 = Interp_kernel1(isoLatDistsX,isoLatDistsZ);
lat2 = Interp_kernel2(isoLatDistsX,isoLatDistsZ);
lat3 = Interp_kernel3(isoLatDistsX,isoLatDistsZ);
if isfield(machineData.kernel,'kernel4')
    lat4 = Interp_kernel4(isoLatDistsX,isoLatDistsZ);
end

dose = lat1 .* func_Di(machineData.betas(1),radDepths) + ...
       lat2 .* func_Di(machineData.betas(2),radDepths) + ...
       lat3 .* func_Di(machineData.betas(3),radDepths);
if isfield(machineData.kernel,'kernel4')   
       dose = dose + lat4 .* (machineData.surfaceDose * exp(log(machineData.electronRangeIntensity) / 17 * radDepths));
end  

% inverse square correction
dose = dose .* (SAD./geoDists(:)).^2;
% check if we have valid dose values and adjust numerical instabilities
% from fft convolution
dose(dose < 0 & dose > -1e-14) = 0;
if any(isnan(dose)) || any(dose<0)
   error('Error in photon dose calculation.');
end
