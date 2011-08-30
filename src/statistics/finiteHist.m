## Copyright (C) 2010 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Return the finite bins and probabilities of a histogram
## Syntax:
##   [xb, px] = finiteHist(hgrm)
## where:
##   hgrm  = histogram struct
##   xb    = finite bins
##   px    = finite probabilities

function [xb, px] = finiteHist(hgrm)

  assert(isHist(hgrm));
  dim = length(hgrm.xb);

  xb = cellfun(@(x) x(2:end-1), hgrm.xb, "UniformOutput", false);
  ii = cellfun(@(x) 2:length(x)-2, hgrm.xb, "UniformOutput", false);
  px = hgrm.px(ii{:});

endfunction
