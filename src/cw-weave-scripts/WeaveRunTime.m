#!/usr/bin/env octapps_run
##
## Estimate the run time of 'lalapps_Weave'.
## Usage:
##   [total, times] = WeaveRunTime("opt", val, ...)
## Options:
##   EITHER:
##     setup_file:      Weave setup file
##   OR:
##     Nsegments:       number of segments
##     Ndetectors:      number of detectors
##     ref_time:        GPS reference time
##     start_time:      GPS start time
##     coh_Tspan:       time span of coherent segments
##     semi_Tspan:      total time span of semicoherent search
##   EITHER:
##     result_file:     Weave result file
##   OR:
##     freq_min/max:    minimum/maximum frequency range
##     dfreq:           frequency spacing
##     f1dot_min/max:   minimum/maximum 1st spindown
##     f2dot_min/max:   minimum/maximum 2nd spindown (optional)
##     NSFTs:           total number of SFTs
##     Fmethod:         F-statistic method used by search
##     Ncohres:         total number of computed coherent results
##     Nsemitpl:        number of computed semicoherent results
##   tau_set:
##     Set of fundamental timing constants to use
##   stats
##     Comma-separated list of statistics being computed
## Outputs:
##   times.total:
##     estimate of total CPU run time (seconds)
##   times.<field>:
##     estimate of CPU time (seconds) to perform action <field>;
##     see the script itself for further documentation

## Copyright (C) 2017 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

function times = WeaveRunTime(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"Nsegments", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"Ndetectors", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"start_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"dfreq", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,scalar,+atmostone:result_file", 0},
               {"f2dot_max", "real,scalar,+atmostone:result_file", 0},
               {"NSFTs", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Fmethod", "char,+exactlyone:result_file", []},
               {"Ncohres", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Nsemitpl", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"tau_set", "char"},
               {"stats", "char"},
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);
  stats = strsplit(stats, ",");

  ## parse fundamental timing constant set
  tau = struct;
  switch tau_set
    case "v2"
      tau_semi_iter_psemi         = 3.31987e-10;   # 75th quantile
      tau_semi_query_psemi        = 2.45808e-08;   # 75th quantile
      tau_coh_coh2f_pcoh          = 7.24469e-06;   # 75th quantile
      tau_semiseg_max2f_psemiseg  = 5.00954e-09;   # 75th quantile
      tau_semiseg_sum2f_psemiseg  = 2.21012e-09;   # 75th quantile
      tau_semi_mean2f_psemi       = 1.12007e-09;   # 75th quantile
      tau_semi_log10bsgl_psemi    = 1.40847e-08;   # 75th quantile
      tau_semi_log10bsgltl_psemi  = 2.47331e-08;   # 75th quantile
      tau_semi_log10btsgltl_psemi = 2.52613e-08;   # 75th quantile
      tau_output_psemi            = 6.59480e-09;   # 75th quantile
      tau_ckpt_psemi              = 0.00000e+00;   # 75th quantile
      demod_fstat_tau0_coreld     = 7.56737e-08;   # 75th quantile
      demod_fstat_tau0_bufferld   = 1.28938e-06;   # 75th quantile
      resamp_fstat_tau0_fbin      = 9.94730e-08;   # 75th quantile
      resamp_fstat_tau0_spin      = 8.68288e-08;   # 75th quantile
      resamp_fstat_tau0_fft       = 4.36694e-10;   # 75th quantile
      resamp_fstat_tau0_bary      = 5.25338e-07;   # 75th quantile
    otherwise
      error("%s: invalid timing constant set '%s'", funcName, tau_set);
  endswitch

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = fitsread(setup_file);
    assert(isfield(setup, "segments"));
    segs = setup.segments.data;
    segment_list = [ [segs.start_s] + 1e-9*[segs.start_ns]; [segs.end_s] + 1e-9*[segs.end_ns] ]';
    segment_props = AnalyseSegmentList(segment_list);
    Nsegments = segment_props.num_segments;
    Ndetectors = length(setup.primary.header.detect);
    ref_time = str2double(setup.primary.header.date_obs_gps);
    start_time = min(segment_list(:));
    coh_Tspan = segment_props.coh_mean_Tspan;
    semi_Tspan = segment_props.inc_Tspan;
  endif

  ## if given, load result file and extract various parameters
  if !isempty(result_file)
    result = fitsread(result_file);
    result_hdr = result.primary.header;
    freq_min = result_hdr.semiparam_minfreq;
    freq_max = result_hdr.semiparam_maxfreq;
    dfreq = result_hdr.dfreq;
    f1dot_min = result_hdr.semiparam_minf1dot;
    f1dot_max = result_hdr.semiparam_maxf1dot;
    f2dot_min = getoptfield(0, result_hdr, "semiparam_minf2dot");
    f2dot_max = getoptfield(0, result_hdr, "semiparam_maxf2dot");
    NSFTs = result_hdr.nsfts;
    Fmethod = result_hdr.fstat_method;
    Ncohres = result_hdr.ncohres;
    Nsemitpl = result_hdr.nsemires;
  endif
  Nsemiseg = Nsemitpl * (Nsegments - 1);

  ## check parameter-space ranges
  assert(freq_max >= freq_min);
  assert(f1dot_max >= f1dot_min);
  assert(f2dot_max >= f2dot_min);

  ## estimate time to iterate over lattice tiling
  time_semi_iter = tau_semi_iter_psemi * Nsemitpl;

  ## estimate time to perform nearest-neighbour lookup queries
  time_semi_query = tau_semi_query_psemi * Nsemitpl;

  ## estimate time to compute coherent F-statistics
  args = struct;
  args.Tcoh = (NSFTs * TSFT) / (Nsegments * Ndetectors);
  args.Tspan = coh_Tspan;
  args.Freq0 = freq_min;
  args.FreqBand = freq_max - freq_min;
  args.dFreq = dfreq;
  args.f1dot0 = f1dot_min;
  args.f1dotBand = f1dot_max - f1dot_min;
  args.f2dot0 = f2dot_min;
  args.f2dotBand = f2dot_max - f2dot_min;
  args.refTimeShift = (ref_time - start_time) / semi_Tspan;
  args.tau0_coreLD = demod_fstat_tau0_coreld;
  args.tau0_bufferLD = demod_fstat_tau0_bufferld;
  args.tau0_Fbin = resamp_fstat_tau0_fbin;
  args.tau0_FFT = resamp_fstat_tau0_fft;
  args.tau0_spin = resamp_fstat_tau0_spin;
  args.tau0_bary = resamp_fstat_tau0_bary;
  args.Tsft = TSFT;
  [resamp_info, demod_info] = fevalstruct(@predictFstatTimeAndMemory, args);
  if strncmpi(Fmethod, "Resamp", 6)
    time_coh_coh2f = resamp_info.tauF_core * Ndetectors * Ncohres;
  elseif strncmpi(Fmethod, "Demod", 5)
    time_coh_coh2f = demod_info.tauF_core * Ndetectors * Ncohres;
  else
    error("%s: unknown F-statistic method '%s'", funcName, Fmethod);
  endif

  ## estimate time to compute semicoherent F-statistics
  time_semiseg_sum2f = tau_semiseg_sum2f_psemiseg * Nsemiseg;
  time_semiseg_max2f = tau_semiseg_max2f_psemiseg * Nsemiseg;
  time_semi_mean2f = tau_semi_mean2f_psemi * Nsemitpl;

  ## estimate time to compute line-robust statistics
  time_semi_log10bsgl = tau_semi_log10bsgl_psemi * Nsemitpl;
  time_semi_log10bsgltl = tau_semi_log10bsgltl_psemi * Nsemitpl;
  time_semi_log10btsgltl = tau_semi_log10btsgltl_psemi * Nsemitpl;

  ## estimate time to output results
  time_output = tau_output_psemi * Nsemitpl;

  ## fill in times struct based on requested statistics
  times = struct;
  times.iter = time_semi_iter;
  times.query = time_semi_query;
  for i = 1:length(stats)
    switch stats{i}
      case "sum2F"
        times.coh_coh2f = time_coh_coh2f;
        times.semiseg_sum2f = time_semiseg_sum2f;
      case "mean2F"
        times.coh_coh2f = time_coh_coh2f;
        times.semiseg_sum2f = time_semiseg_sum2f;
        times.semi_mean2f = time_semi_mean2f;
      case "log10BSGL"
        times.coh_coh2f = time_coh_coh2f;
        times.semi_log10bsgl = time_semi_log10bsgl;
      case "log10BSGLtL"
        times.coh_coh2f = time_coh_coh2f;
        times.semiseg_sum2f = time_semiseg_sum2f;
        times.semiseg_max2f = time_semiseg_max2f;
        times.semi_log10bsgltl = time_semi_log10bsgltl;
      case "log10BtSGLtL"
        times.coh_coh2f = time_coh_coh2f;
        times.semiseg_sum2f = time_semiseg_sum2f;
        times.semiseg_max2f = time_semiseg_max2f;
        times.semi_log10btsgltl = time_semi_log10btsgltl;
      otherwise
        error("%s: invalid statistic '%s'", funcName, stats{i});
    endswitch
  endfor
  times.output = time_output;

  ## estimate total run time
  times.total = sum(structfun(@sum, times));

endfunction
