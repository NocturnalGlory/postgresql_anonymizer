Definitions of the terms used in this project
==============================================================================


Two main strategies are used:

* **Dynamic Masking** offers an altered view of the real data without
  modifying it. Some users may only read the masked data, others may access
  the authentic version.

* **Permanent Destruction** is the definitive action of substituting the
  sensitive information with uncorrelated data. Once processed, the authentic
  data cannot be retrieved.

The data can be altered with several techniques:

1. **Deletion** or **Nullification** simply removes data.

2. **Static Subtitution** consistently replaces the data with a generic
   values. For instance: replacing all values of TEXT column with the value
   "CONFIDENTIAL".

3. **Variance** is the action of "shifting" dates and numeric values. For
   example, by applying a +/- 10% variance to a salary column, the dataset will
   remain meaningful.

4. **Generalization** reduces the accuracy of the data by replacing it with a 
   range of values. Instead of saying "Bob is 28 years old", you can say "Bob 
   is between 20 and 30 years old". This is useful for analytics because the
   data remains true.

5. **Shuffling** mixes values within the same columns. This method is open to
   being reversed if the shuffling algorithm can be deciphered.

6. **Randomization** replaces sensitive data with **random-but-plausible**
   values. The goal is to avoid any identification from the data record while
   remaining suitable for testing, data analysis and data processing.

7. **Partial scrambling** is similar to static substitution but leaves out some
   part of the data. For instance : a credit card number can be replaced by
   '40XX XXXX XXXX XX96'

8. **Custom rules** are designed to alter data following specific needs. For
   instance, randomizing simultanously a zipcode and a city name while keeping
   them coherent.

Please note that **Encryption** and **Hashing** are not considered as anonymization
techniques, because they requires additional information (a private key or a salt)
and if this information is stolen, then the authentic data can be revealed.

