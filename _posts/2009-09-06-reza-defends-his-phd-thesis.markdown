---
date: '2009-09-06 21:21:02'
layout: post
slug: reza-defends-his-phd-thesis
status: publish
title: Reza defends his Ph.D. Thesis
wordpress_id: '1269'
categories:
- News
---


[![Reza defends his Ph.D. thesis](http://natlang.cs.sfu.ca/wp-content/uploads/2009/09/img_4296-300x207.jpg)](http://natlang.cs.sfu.ca/wp-content/uploads/2009/09/img_4296.jpg)

Gholamreza Haffari successfully defended his Ph.D. thesis on August 17th, 2009. His thesis is entitled _Machine Learning Approaches To Dealing with Limited Training Data in Statistical Machine Translation_. His external examiner was [Kevin Knight](http://www.isi.edu/~knight/). His internal examiner was [Oliver Schulte](http://www.cs.sfu.ca/~oschulte/). His senior supervisor was [Anoop Sarkar](http://www.cs.sfu.ca/~anoop/) and his supervisory committee included: [Greg Mori](http://www.cs.sfu.ca/~mori/), [Shaojun Wang](http://www.engineering.wright.edu/~swang/), and [Valentine Kabanets](http://www.cs.sfu.ca/~kabanets/). [Torsten Moller]() chaired the defense.

Here is the abstract of his thesis:

> Statistical Machine Translation (SMT) models learn how to translate by examining a bilingual parallel corpus containing sentences aligned with their human-produced translations. However, high quality translation output is dependent on the availability of massive amounts of parallel text in the source and target languages. There are a large number of languages that are considered _low-density_, either because the population speaking the language is not very large, or even if millions of people speak the language, insufficient online resources are available in that language. This thesis covers machine learning approaches for dealing with such situations in statistical machine translation where the amount of available bilingual data is limited.
> 
> The problem of learning from insufficient labeled training data has been dealt with in machine learning community under two general frameworks: (i) Semi-supervised Learning, and (ii) Active Learning. The complex nature of machine translation task poses severe challenges to most of the algorithms developed in machine learning community for these two learning scenarios. In this thesis, I develop semi-supervised learning as well as  active learning algorithms to deal with the shortage of bilingual training data for Statistical Machine Translation task, specific to cases where there is shortage of bilingual training data.
> 
> I assume that we are given access to a monolingual corpus containing large number of sentences in the source language, in addition to a small or moderate sized bilingual corpus. The idea is to take advantage of this readily available monolingual data in building a better SMT model using bootstrapping-style methods: By _selecting_ an important subset of these monolingual sentences, _preparing_ their translations, and using them together with the original sentence pairs to _re-train_ the SMT model effectively. When preparing the translation of the selected sentences, if we use a human annotator, then the framework fits into the Active Learning scenario in machine learning. Instead if we use the (system generated) translations from the output of the SMT model itself, then the framework fits into the semi-supervised learning scenario in machine learning. The key points that I address throughout this thesis are (1) how to choose the important sentences, (2) how to provide their translations (possibly with as little effort as possible), and (3) how to use the newly collected information in training the SMT model.



