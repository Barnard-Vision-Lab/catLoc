# catLoc
Psychtoolbox code for the "catLoc" fMRI localizer experiment, which helps define category-selective ventral temporal regions.

BACKGROUND: 

This experiment was initially developed by Alex White in collaboration Jason Yeatman, at Stanford University. 
It was inspired by the "fLoc" experiment by Kalanit Grill-Spector's lab (http://vpnl.stanford.edu/fLoc/), which serves a similar purpose. We were most interested in defining text-selective VOTC regions (aka the 'visual word form area). We also took different approaches to balancing the low-level visual features across conditions. In fLoc all images are presented on textured backgrounds. We did not do that, but we did include two "false fonts" (BACS-2 and PseudoSloan) against which to compare the response to familiar letter strings (in Courier New and Sloan).  Those fonts are matched in several visual features.  

The other big change was that we present 3 images on each frame: one small one at the screen center and one big one to either side. That was to ensure that we were stimulating any voxels that might be sensitive to the visual periphery. But the code can be modified to present just 1 foveal stimulus on every trial (as in fLoc). 

We first described catLoc in this paper: White, A. L., Kay, K. N., Tang, K. A., & Yeatman, J. D. (2023). Engaging in word recognition elicits highly specific modulations in visual cortex. Current Biology, 33, 1308–1320. https://doi.org/10.1016/j.cub.2023.02.042. 

The version of the experiment shared here was further developed by Alex White and Vassiki Chauhan at Barnard College, Columbia University. We removed the "objects" category and added a "limbs" category (pictures of hands, arms, legs, feet). 

The images of faces, limbs, and objects were kindly provided by Kalanit Grill-Spector. Edited versions of those are saved in .mat files in /code/stimulusGeneration. 

The false fonts are provided in as OTF files in code/stimulus. They came from two sources: 
(1) BACS-2, designed to match Courier New.  Public Repo: https://osf.io/dj8qm/. Publication: Vidal, C., Content, A., & Chetail, F. (2017). BACS: The Brussels Artificial Character Sets for studies in cognitive psychology and neuroscience. Behavior Research Methods, 49, 2093–2112. DOI: 10.3758/s13428-016-0844-8
(2) PseudoSloan, designed to match Sloan. This was developed in Anthony Norcia's lab at Stanford. Public repo: https://osf.io/qhj2b/ Publication: Vildavski, V. Y., Verde, L. Lo, Blumberg, G., Parsey, J., & Norcia, A. M. (2022). PseudoSloan: A perimetric-complexity and area-controlled font for vision and reading research. Journal of Vision, 22, 1–5. DOI: 10.1167/jov.22.10.7

INSTRUCTIONS FOR USE: 

- This code requires Psychtoolbox 3 (http://psychtoolbox.org/). It was developed and tested with MATLAB 2022. There may be some dependencies in this toolbox: https://github.com/alexlwhite/AWToolboxes/. 
- The script that runs the experiment is catLoc_Script.m See comments at the start of that script that provide instructions for how to get started.
- Before running that script, you need to: 
   - set all stimulus and task parameters in the catLoc_Params function. 
   - specify details about the screen used in the experiment, in the getDisplayParameters function. 
   - Run code to generate images of the stimuli: stimulusGeneration/makeCatLocStimScript.m. The images are saved in catLoc/stimuli/{displayName} and then loaded in during the experiment. 

Contact alwhite@barnard.edu with questions. This README will be updated as necessary. 
