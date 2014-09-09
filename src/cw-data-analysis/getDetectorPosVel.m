## Copyright (C) 2012 Karl Wette
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Compute the spin, orbital, and total components of a detector's
## position and velocity at a list of GPS times, using LALPulsar
## Usage:
##   [p, v, sp, sv, op, ov] = getDetectorPosVel("opt", val, ...)
## where:
##   p  = detector positions, in equatorial coordinates
##   v  = detector velocities, in equatorial coordinates
##   sp = spin components of detector positions
##   sv = spin components of detector velocities
##   op = orbital components of detector positions
##   ov = orbital components of detector velocities
## Options:
##   "gps_times":   list of GPS times
##   "detector":    name of detector (default: H1)
##   "motion":      type of motion (default: spin+orbit)
##   "ephemerides": Earth/Sun ephemerides from loadEphemerides()
function [p, v, sp, sv, op, ov] = getDetectorPosVel(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"gps_times", "real,strictpos,vector"},
               {"detector", "char", "H1"},
               {"motion", "char", "spin+orbit"},
               {"ephemerides", "a:swig_ref", []},
               []);

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## parse detector string
  multiIFO = new_MultiLALDetector();
  detNames = XLALCreateStringVector(detector);
  XLALParseMultiLALDetector(multiIFO, detNames, []);
  if multiIFO.length != 1
    error("%s: can only return positions and velocities for a single detector", funcName);
  endif

  ## parse detector motion string
  detMotion = XLALParseDetectorMotionString(motion);

  ## allocate arrays for holding spin and orbital positions and velocities
  sp = sv = op = ov = zeros(3, length(gps_times));

  ## iterate over GPS times
  spv = new_PosVel3D_t();
  opv = new_PosVel3D_t();
  for i = 1:length(gps_times)

    ## get detector spin and orbital position and velocity at given GPS time
    XLALDetectorPosVel(spv, opv, LIGOTimeGPS(gps_times(i)), multiIFO.sites{1}, ephemerides, detMotion);

    ## store spin position and velocity, converting to physical units
    sp(:, i) = spv.pos * LAL_C_SI;
    sv(:, i) = spv.vel * LAL_C_SI;

    ## store orbital position and velocity, converting to physical units
    op(:, i) = opv.pos * LAL_C_SI;
    ov(:, i) = opv.vel * LAL_C_SI;

  endfor

  ## calculate total detector position and velocity
  p = sp + op;
  v = sv + ov;

endfunction