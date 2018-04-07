## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Computes the semicoherent global correlation transform metric, as
## given in Pletsch, PRD 82 042002 (2010), which Taylor-expands the
## Earth's orbital motion.
## Syntax:
##   g = GCTSemicoherentTaylorMetric("opt", val, ...)
## where:
##   g = semicoherent GCT metric using Taylor-expanded phase model
## Options:
##   "smax":    number of spindowns (up to second spindown)
##   "tj_list": list of values of tj, the mid-point of the coherent
##              time span of each segment
##   "t0":      value of t0, an overall reference time
##   "T":       value of T, the coherent time span
##   "Omega":   value of Omega, the Earth's angular rotation frequency
##              (default: 2*pi / (sidereal day in seconds)

function g = GCTSemicoherentTaylorMetric(varargin)

  ## parse options
  parseOptions(varargin,
               {"smax", "integer,strictpos,scalar"},
               {"tj_list", "real,vector"},
               {"t0", "real,scalar"},
               {"T", "real,strictpos,scalar"},
               {"Omega", "real,strictpos,scalar", 7.29211585537707e-05},
               []);

  ## check options
  assert(smax <= 2, "Only up to second spindown supported");

  ## create coordinate indices
  [ii{1:5}] = deal([]);
  ii([1:smax+1,4,5]) = num2cell(1:3+smax);
  [nu, nud, nudd, nx, ny] = deal(ii{:});

  ## various constants for computing elements
  phi = Omega * T / 2;
  cos_phi = cos(phi);
  sin_phi = sin(phi);
  j0_phi = sin_phi / phi;   ## spherical Bessel functions
  j1_phi = sin_phi / phi^2 - cos_phi / phi;
  j2_phi = ( (3/phi^2 - 1) * sin_phi / phi ) - ( 3 * cos_phi / phi^2 );
  j3_phi = ( (15/phi^3 - 6/phi) * sin_phi / phi ) - ( (15/phi^2 - 1) * cos_phi / phi );
  inv_N = 1 / length(tj_list);
  mu1 = inv_N .* sum( ( ( tj_list - t0 )./T ).^1 );
  mu2 = inv_N .* sum( ( ( tj_list - t0 )./T ).^2 );
  mu3 = inv_N .* sum( ( ( tj_list - t0 )./T ).^3 );
  mu4 = inv_N .* sum( ( ( tj_list - t0 )./T ).^4 );
  mu0SIN = inv_N .* sum( ( ( tj_list - t0 )./T ).^0 .* sin( Omega.*tj_list ) );
  mu1SIN = inv_N .* sum( ( ( tj_list - t0 )./T ).^1 .* sin( Omega.*tj_list ) );
  mu2SIN = inv_N .* sum( ( ( tj_list - t0 )./T ).^2 .* sin( Omega.*tj_list ) );
  mu0COS = inv_N .* sum( ( ( tj_list - t0 )./T ).^0 .* cos( Omega.*tj_list ) );
  mu1COS = inv_N .* sum( ( ( tj_list - t0 )./T ).^1 .* cos( Omega.*tj_list ) );
  mu2COS = inv_N .* sum( ( ( tj_list - t0 )./T ).^2 .* cos( Omega.*tj_list ) );
  xi2SIN = inv_N .* sum( sin( Omega.*tj_list ).^2 );
  xi2COS = inv_N .* sum( cos( Omega.*tj_list ).^2 );
  xi1SINCOS = inv_N .* sum( sin( Omega.*tj_list ).*cos( Omega.*tj_list ) );

  ## initial metric is NaNs to ensure each element is computed
  g = nan(3 + smax, 3 + smax);

  ## compute metric elements
  g(nu, nu) = 1/3;
  g(nu, nx) = g(nx, nu) = -j1_phi*mu0SIN;
  g(nu, ny) = g(ny, nu) = j1_phi*mu0COS;
  g(nx, nx) = 1/2 - 1/2*j0_phi*cos_phi - j1_phi*sin_phi*xi2COS;
  g(nx, ny) = g(ny, nx) = -j1_phi*sin_phi*xi1SINCOS;
  g(ny, ny) = 1/2 - 1/2*j0_phi*cos_phi - j1_phi*sin_phi*xi2SIN;
  if !isempty(nud)
    g(nu, nud) = g(nud, nu) = 4/3*mu1;
    g(nud, nud) = 4/45 + 16/3*mu2;
    g(nud, nx) = g(nx, nud) = -2/3*j2_phi*mu0COS - 4*j1_phi*mu1SIN;
    g(nud, ny) = g(ny, nud) = -2/3*j2_phi*mu0SIN + 4*j1_phi*mu1COS;
    if !isempty(nudd)
      g(nu, nudd) = g(nudd, nu) = 1/5 + 4*mu2;
      g(nud, nudd) = g(nudd, nud) = 4/3*mu1 + 16*mu3;
      g(nudd, nudd) = 1/7 + 8*mu2 + 48*mu4;
      g(nudd, nx) = g(nx, nudd) = (-3/5*j1_phi + 2/5*j3_phi)*mu0SIN - 4*j2_phi*mu1COS - 12*j1_phi*mu2SIN;
      g(nudd, ny) = g(ny, nudd) = (3/5*j1_phi - 2/5*j3_phi)*mu0COS - 4*j2_phi*mu1SIN + 12*j1_phi*mu2COS;
    endif
  endif

endfunction

## check GCT implementation against numerical metrics generated by Maxima script CheckGCTTaylorMetrics.wxm
%!function __test_gctsemi(tj_list, t0, T, gref)
%!  g = GCTSemicoherentTaylorMetric("smax", 2, "tj_list", tj_list, "t0", t0, "T", T, "Omega", 2*pi);
%!  assert(all(abs(g - gref) < 1e-10));

%!test __test_gctsemi([-2, -1, 0, 1, 2], 0, 1, ...
%!                    [ ...
%!                      0.33333333333333,0,8.2,0,0.31830988618379; ...
%!                      0,10.75555555555555,0,-0.20264236728467,0.0; ...
%!                      8.2,0,342.5428571428571,0.0,7.76423794799557; ...
%!                      0,-0.20264236728467,0.0,0.5,0; ...
%!                      0.31830988618379,0.0,7.76423794799557,0,0.5; ...
%!                    ]);

%!test __test_gctsemi([-4, -2, 0, 2, 4], 0, 1, ...
%!                    [ ...
%!                      0.33333333333333,0,32.2,0,0.31830988618379; ...
%!                      0,42.75555555555555,0,-0.20264236728467,0.0; ...
%!                      32.2,0,5286.542857142857,0.0,30.6825497532285; ...
%!                      0,-0.20264236728467,0.0,0.5,0; ...
%!                      0.31830988618379,0.0,30.6825497532285,0,0.5; ...
%!                    ]);

%!test __test_gctsemi([-10, -6, 5, 2, 9], -1, 2.5, ...
%!                    [ ...
%!                      0.33333333333333,0.53333333333334,32.32800000000034,8.881784197001253e-17,0.016211389382774; ...
%!                      0.53333333333334,42.92622222222272,80.2005333333349,0.080754439908228,0.025938223012437; ...
%!                      32.32800000000034,80.2005333333349,4626.441737142834,0.19381065577974,1.609575867543293; ...
%!                      8.881784197001253e-17,0.080754439908228,0.19381065577974,0.48378861061722,8.639163721880971e-18; ...
%!                      0.016211389382774,0.025938223012437,1.609575867543293,8.639163721880971e-18,0.5; ...
%!                    ]);

## check refinement of GCT metric implementation against expressions by Prix&Shaltev from CostFunctionsEaHGCT()
%!function ret = refinement ( s, Nseg )
%!  gam1 = sqrt ( 5 * Nseg.^2 - 4 );	## Eq.(77) in Pletsch(2010)
%!  switch ( s )
%!    case 1
%!      ret = gam1;
%!    case 2
%!      ret = gam1 .* sqrt ( (35 * Nseg.^4 - 175 * Nseg.^2  + 143)/3 ); ## Eq.(96) in Pletsch(2010), 'fixed' to give gam(1)=1
%!    otherwise
%!      error ("Invalid value of s: '%f' given, allowed are {1,2}\n", s );
%!  endswitch

%!test
%!  T = 5;
%!  N = 10;
%!  t_j = ((1:N) - (N+1)/2)*T;
%!  for s = 1:2
%!    GCT_semi = GCTSemicoherentTaylorMetric("smax", 1, "tj_list", t_j, "t0", mean(t_j), "T", T, "Omega", 2*pi);
%!    GCT_coh = GCTCoherentTaylorMetric("smax", 1, "tj", mean(t_j), "t0", mean(t_j), "T", T, "Omega", 2*pi);
%!    GCT_refine = sqrt(det(GCT_semi) / det(GCT_coh));
%!    GCT_refine_ref = refinement(1, N);
%!    assert(abs(GCT_refine - GCT_refine_ref) < 0.005*GCT_refine_ref);
%!  endfor
