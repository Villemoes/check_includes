Some header bloat statistics
============================

Here are some graphs showing the evolution of various metrics for the
"header bloat" phenomenon for the Linux kernel. For each release, I've
done a ``make defconfig`` followed by ``make vmlinux`` (for native,
i.e. x86-64), then used the ``.o.cmd`` files generated to figure out
which header files each ``.c`` file ended up including recursively.

From these, I extracted/computed these metrics for each translation unit:

* *hcount*, the total number of included headers;
* *csize*, the size of ``.c`` file (bytes);
* *tsize*, total size of translation unit (``.c`` file plus all
  recursively included headers);
* *cloc*, the number of lines in ``.c`` file;
* *tloc*, the total number of lines in translation unit;
* *crloc* and *trloc*, a kind of »reduced« line count after doing the
  most basic preprocessing: removal of comments and ``#if 0`` blocks,
  again for both the ``.c`` file and the whole translation unit; and
  finally
* the ratios *rsize* = *tsize*/*csize*, *rloc* = *tloc*/*cloc*, and
  *rrloc* = *trloc*/*crloc*.

In addition to these, a few global statistics were recorded: The total
number of translation units and the build time (wallclock, system and
user).
  
Various details:

* Each header is only counted once, though a few deliberately do not
  have include guards and are included multiple times.
* vBLA-x is just vBLA with ``63a3f603413f`` (timeconst.pl: Eliminate
  Perl warning) cherry-picked.
* Timings are average of 5 ``make -j8 vmlinux`` runs, each done after
  a ``make clean`` and a ``git grep blablabla`` to warm up the page
  cache.
* I've excluded ``scripts/`` and ``tools/``, my stupid script got
  confused by the stuff found there. The timings obviously include
  time spent building those directories, but it shouldn't skew the
  picture too much. Similarly, the timings include various linking
  steps, so e.g. "wallclock time per translation unit" should be taken
  with a grain of salt.
* The compiler was gcc 4.9, but that really only matters for the
  timing results, the LOC statistics are (should be) independent of
  the compiler.
* I must have messed up when doing v4.15 - I think my laptop ended up
  running on battery or something during parts of the v4.15
  builds. Anyway, again, it only matters for the timing results.

All this data can of course be visualized in various ways. First,
let's look at how the kernel has grown in terms of the number of
translation units, and how long it takes to compile it.

.. image:: time_ntu.png

Expectedly, as the kernel grows more features, there are more
translation units, and hence a longer build time. However, one may
sense that the build time increases faster than #TUs. Indeed, let's
make the same plot, but with v3.0 as a baseline (this also clearly
shows I goofed making the v4.15 timing comparable to the others):

.. image:: time_ntu_normalized.png

While v4.14 consisted of about 36% more TUs than v3.0, it takes almost
exactly twice as long to compile.

Let's look at how big these translation units are.

.. image:: csize.png

.. image:: cloc.png

The drop at v4.14 (and the above seen increase in the number of TUs)
can both be explained by ``b9e1486e0e4b`` causing a large part of
``drivers/media/rc/`` becoming part of an x86-64 defconfig build,
which was then fixed by ``5573d124292a``.

The first and second quartiles of the size of the ``.c`` files are
remarkably consistent, while the average increases from about 20.5kB
to 23.0kB, and the 75th percentile increases from 23.8kB to 26.5kB.

Looking at the total size of the translation units shows a different
picture:

.. image:: tsize.png

.. image:: tloc.png

We clearly see the effect of the sched.h cleanup in the 4.11
cycle. Unfortunately, the trend has continued since then, to the point
that both the average and median translation unit now consists of 3MB,
100000 lines.

Finally, let's look at how the »bloat factors« *tsize*/*csize* and
*tloc*/*cloc* behave, and whether it is »just« the headers that
increase in size, or if new ones are also added.

.. image:: rsize.png

.. image:: rloc.png

.. image:: hcount.png

So the typical (median) translation unit ends up including over 450
headers files, making the whole TU about 200 times bigger than the .c
file itself, while more than 25% of the translation units get bloated
to over 400 times the size of the .c file.

Clearly something happened in 3.7 that didn't really affect the total
TU size, but did make everything include more headers. Incidentally,
the UAPI split was merged in 3.7. Now go read `XKCD 552
<https://xkcd.com/552/>`_.

	   
The `raw data <data.tar.gz>`_ is available.
