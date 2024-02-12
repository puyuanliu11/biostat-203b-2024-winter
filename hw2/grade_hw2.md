*Puyuan Liu*

### Overall Grade: 160/180

### Quality of report: 5/10

-   Is the homework submitted (git tag time) before deadline? Take 10 pts off per day for late submission.  

-   Is the final report in a human readable format html? 

-   Is the report prepared as a dynamic document (Quarto) for better reproducibility?

-   Is the report clear (whole sentences, typos, grammar)? Do readers have a clear idea what's going on and how results are produced by just reading the report? Take some points off if the solutions are too succinct to grasp, or there are too many typos/grammar. 

    No Name. `-5.0`

### Completeness, correctness and efficiency of solution: 123/130

- Q1 (20/20)

    - Q1.2 Run time should be faster, and the memory usage should be smaller with about 40 MB (e.g., 41.51 MB) by changing categorical variables to factor types.

- Q2 (73/80)

    - Q2.1 (10/10)
    
    - Q2.2 (10/10)
    
    - Q2.3 (15/15)
    
    - Q2.4 (10/15)
    
      `charttime` did not match because of a different timezone. Need to mention or fix this. `-5.0`
    
    - Q2.5 (13/15)

      `charttime` did not match because of a different timezone. Need to mention or fix this. `-0.0`
      
      The binary Parquet file should be 1.9 GB (2070040265 B). 2070040265 is not 2.0 GB. `-2.0`
      
    - Q2.6 (15/15)
    
- Q3 (30/30)
	    
### Usage of Git: 10/10

-   Are branches (`main` and `develop`) correctly set up? Is the hw submission put into the `main` branch?

-   Are there enough commits (>=5) in develop branch? Are commit messages clear? The commits should span out not clustered the day before deadline. 

-   Is the hw2 submission tagged? 

-   Are the folders (`hw1`, `hw2`, ...) created correctly? 
  
-   Do not put a lot auxiliary files into version control. 

    All yes


### Reproducibility: 10/10

-   Are the materials (files and instructions) submitted to the `main` branch sufficient for reproducing all the results? Just click the `Render` button will produce the final `html`? 

    Yes

-   If necessary, are there clear instructions, either in report or in a separate file, how to reproduce the results?

### R code style: 12/20

For bash commands, only enforce the 80-character rule. Take 2 pts off for each violation. 

-   [Rule 2.5](https://style.tidyverse.org/syntax.html#long-lines) The maximum line length is 80 characters. Long URLs and strings are exceptions.  

-   [Rule 2.4.1](https://style.tidyverse.org/syntax.html#indenting) When indenting your code, use two spaces.  

-   [Rule 2.2.4](https://style.tidyverse.org/syntax.html#infix-operators) Place spaces around all infix operators (=, +, -, &lt;-, etc.).  

-   [Rule 2.2.1.](https://style.tidyverse.org/syntax.html#commas) Do not place a space before a comma, but always place one after a comma.  

-   [Rule 2.2.2](https://style.tidyverse.org/syntax.html#parentheses) Do not place spaces around code in parentheses or square brackets. Place a space before left parenthesis, except in a function call.

    Lines 161, 179 (331), 217 (257, 291), 220 (219, 259, 293). `-8.0`

