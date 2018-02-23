set offsets 0.5, 0.5, 0, 0
set boxwidth 0.16 absolute
set style fill   solid 1.00 border lt -1
set xtics rotate
set y2tics
set ytics nomirror
set key autotitle columnhead
set termoption enhanced

data="defconfig.out"

set term png size 1200,400
set output "time_ntu.png"
set ylabel "Time (s)"
set y2label "#TUs"
set key left top
plot [][0:][][0:] data using ($0-0.24):"wtime" with boxes title "Wallclock time",\
     '' using ($0-0.08):"stime":xticlabels(1) with boxes title "System time",\
     '' using ($0+0.08):"utime" with boxes title "User time",\
     '' using ($0+0.30):"ntu" with boxes axes x1y2 title "#Translation Units"

rel_wtime(x) = x/($0 > 0 ? base_wtime : base_wtime = x)
rel_stime(x) = x/($0 > 0 ? base_stime : base_stime = x)
rel_utime(x) = x/($0 > 0 ? base_utime : base_utime = x)
rel_ntu(x)   = x/($0 > 0 ? base_ntu   : base_ntu = x)
set output "time_ntu_normalized.png"
set ylabel "Ratio to v3.0"
set y2label ""
set key left top

#(first_wtime(column("wtime")), column("wtime")/base_wtime)

plot [][0:] data using ($0-0.24):(rel_wtime(column("wtime"))) \
     with boxes title "Wallclock time",\
     '' using ($0-0.08):(rel_stime(column("stime"))):xticlabels(1) \
     with boxes title "System time",\
     '' using ($0+0.08):(rel_utime(column("utime"))) \
     with boxes title "User time",\
     '' using ($0+0.30):(rel_ntu(column("ntu"))) \
     with boxes title "#Translation Units"

set title ''
set output "csize.png"
set ylabel "bytes"
set key outside center top horizontal title "Distribution of {/:Italic csize}"
plot [][0:] data using 0:"csize_q25":xticlabels(1) title 'Q1',\
     '' using 0:"csize_median" title 'Median',\
     '' using 0:"csize_mean" title 'Mean',\
     '' using 0:"csize_q75" title 'Q3'

set title ''
set output "cloc.png"
set ylabel "LOC"
set key outside center top horizontal title "Distribution of {/:Italic cloc}"
plot [][0:] data using 0:"cloc_q25":xticlabels(1) title 'Q1', \
     '' using 0:"cloc_median" title 'Median', \
     '' using 0:"cloc_mean" title 'Mean', \
     '' using 0:"cloc_q75" title 'Q3'


set title ''
set output "tsize.png"
set ylabel "kilobytes"
set key outside center top horizontal title "Distribution of {/:Italic tsize}"
plot [][0:] data using 0:(column("tsize_q25")/1000):xticlabels(1) title 'Q1',\
     '' using 0:(column("tsize_median")/1000) title 'Median',\
     '' using 0:(column("tsize_mean")/1000) title 'Mean',\
     '' using 0:(column("tsize_q75")/1000) title 'Q3'

set title ''
set output "tloc.png"
set ylabel "LOC"
#set title "Distribution of .c sizes"
set key outside center top horizontal title "Distribution of {/:Italic tloc}"
plot [][0:] data using 0:"tloc_q25":xticlabels(1) title 'Q1', \
     '' using 0:"tloc_median" title 'Median', \
     '' using 0:"tloc_mean" title 'Mean', \
     '' using 0:"tloc_q75" title 'Q3'

set title ''
set output "rsize.png"
set ylabel ""
set key outside center top horizontal title "Distribution of {/:Italic rsize}"
plot [][0:] data using 0:(column("rsize_q25")):xticlabels(1) title 'Q1',\
     '' using 0:(column("rsize_median")) title 'Median',\
     '' using 0:(column("rsize_q75")) title 'Q3'

set title ''
set output "rloc.png"
set ylabel ""
set key outside center top horizontal title "Distribution of {/:Italic rloc}"
plot [][0:] data using 0:"rloc_q25":xticlabels(1) title 'Q1', \
     '' using 0:"rloc_median" title 'Median', \
     '' using 0:"rloc_q75" title 'Q3'

set title ''
set output "hcount.png"
set ylabel "#headers"
#set title "Distribution of .c sizes"
set key outside center top horizontal title "Distribution of {/:Italic hcount}"
plot [][0:] data using 0:"hcount_q25":xticlabels(1) title 'Q1', \
     '' using 0:"hcount_median" title 'Median', \
     '' using 0:"hcount_mean" title 'Mean', \
     '' using 0:"hcount_q75" title 'Q3'



# plot [][0:][][0:] data using ($0):(0*$1):xticlabels(1) with boxes title '',\
#      '' using ($0-0.2):(column("wtime")/column("ntu")) with boxes title "wallclock time per TU",\
#      '' using ($0+0.2):(column("utime")/column("stime")) with boxes axes x1y2 title "user/sys time ratio"



# plot [][0:] data using ($0-0.3):($2/$5) with boxes, '' using ($0+0.3):($3/$5) with boxes, '' using ($0):($4/$5):xticlabels(1) with boxes
