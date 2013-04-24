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

## Returns the mean of a histogram.
## Syntax:
##   mean = meanOfHist(hgrm)
## where:
##   hgrm = histogram struct

function mean = meanOfHist(hgrm)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);

  ## calculate mean
  mean = zeros(dim, 1);
  for k = 1:dim
    n = zeros(dim, 1);
    n(k) = 1;
    mean(k) = momentOfHist(hgrm, zeros(dim, 1), n);
  endfor

endfunction
