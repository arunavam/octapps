## Copyright (C) 2011 Karl Wette
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

## Generates values for random parameters, given a generator
## Syntax:
##   [v, v, ...] = NextRandParam(rng, N)
## where
##   rng = random parameter generator
##   N   = number of values to generate
##   v   = values of random parameter

function varargout = NextRandParam(rng, N)

  ## load GSL wrappers
  gsl;

  ## check input arguments
  if !exist("N")
    N = 1;
  endif
  if nargout ~= length(rng.rii) + length(rng.cii);
    error("Incorrect number of output arguments!");
  endif

  ## fill random parameters with next quasi-random vector
  if length(rng.rii) > 0
    r = rng.q.get(N);
    [varargout{rng.rii}] = deal(mat2cell(rng.rm(:,ones(N,1)) .* r + ...
					 rng.rc(:,ones(N,1)),ones(length(rng.rii),1),N){:});
  endif

  ## fill constant parameters
  if length(rng.cii) > 0
    [varargout{rng.cii}] = deal(mat2cell(rng.cc(:,ones(N,1)),ones(length(rng.cii),1),N){:});
  endif

endfunction
