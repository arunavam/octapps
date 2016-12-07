## Copyright (C) 2015 Karl Wette
## Copyright (C) 2011 Reinhard Prix
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

## Creates a histogram representing a Gaussian PDF with given mean and standard deviation
## Usage:
##   hgrm = createGaussianHist("opt", val, ...)
## where:
##   hgrm = Gaussian PDF histogram
## Options are:
##   "mean":     mean of the Gaussian distribution
##   "std":      standard deviation
##   "binsize":  histogram bin-size (default = "std" / 10)
##   "domain":   constrain all samples to lie within this interval [min(domain), max(domain)]
##
function hgrm = createGaussianHist ( varargin )

  ## parse optional keywords
  uvar = parseOptions(varargin,
                      {"mean", "real,scalar"},
                      {"std", "real,strictpos,scalar"},
                      {"binsize", "real,scalar", []},
                      {"domain", "real,vector", []},
                      []);
  if isempty(uvar.binsize)
    uvar.binsize = uvar.std / 10.0;
  endif
  if isempty(uvar.domain)
    uvar.domain = uvar.mean + [-10, 10] * uvar.std;
  endif

  ## create 1D histogram object
  hgrm = Hist( 1, {"lin", "dbin", uvar.binsize} );

  ## initialise histogram to a Gaussian PDF
  hgrm = initHistFromFunc(hgrm, @(x) normpdf(x, uvar.mean, uvar.std), uvar.domain);

endfunction


## generate Gaussian histogram and check its properties
%!shared hgrm
%!  hgrm = createGaussianHist(1.2, 3.4, "binsize", 0.1);
%!assert(abs(meanOfHist(hgrm) - 1.2) < 0.1)
%!assert(abs(sqrt(varianceOfHist(hgrm)) - 3.4) < 0.1)
