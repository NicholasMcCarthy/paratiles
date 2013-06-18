Color Deconvolution
===================

This repository contains Mathematica notebooks for calculating both
supervised and unsupervised color deconvolution of digital images.
This work was intended to assist naive users in the analysis of
stained histology samples by quatifying the amount of each stain
in each pixel of the image.

Supervised Methods
------------------

The canonical method is the unsupervised method of Ruifrok and
Johnston in their paper "Quantification of Histochemical Staining by
Color Deconvolution". A copy of the paper is included in the "Reference"
directory.

The notebook "Ruifrok and Johnston Walkthrough" contains worked examples
and code showing how the calculations can be done. It also includes some
useful code showing how to display intermediate and final results.

The Ruifrok method works for our purposes, but requires a tedious and
error prone series of staining procedures to generate calibration
values for the color basis matrix of the dyes.

Unsupervised Methods
--------------------

A more useful method would be an unsupervised method capable of
determining the color basis matrix without input from the operator.

The first of these methods to be examined was that of Newberg and
Murphy in "A Framework for the Automated Analysis of Subcellular
Patterns in Human Protein Atlas Images". A copy of the paper is in the
"Reference" directory.

Again, notes containining worked examples and code are in the
Mathematical notebook file "Newberg and Murphy Walkthrough". This
paper included MATLAB code to do the calculations. The notes show how
that code was translated to Mathematica as well.

This method was found to be extremely slow and unreliable. Additional
work on this method was quickly abandoned.

The third method examined, and the most successful, was that of
Macenko, *et al*., in the paper "A Method for Normalizing Histology
Slides for Quantitative Analysis", a copy of which is also included
in the "Reference" directory.

This method is the most intuitively satisfying in my opinion. A
walkthrough is included in the Mathematica notebook entitled
"Macenko et al Walkthrough". Although it does a good job of
deconvolving the colors in an image, it does not always match
the color basis that would be obtained by supervised methods. Of
particular note is that, for the stain images examined, it can
often be fooled by the presence of red blood cells in the image.

Requirements
------------

If you don't have Mathematica, you should be able to read the notebooks
using the free Mathematica Viewer.

The images used in the walkthroughs are in the "Images" directory. If
you wish to run or alter the notebooks, you may have to revised the
hardwired paths to the images included in the notebook files.
