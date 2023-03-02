


# JfEE



<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [What it Does](#what-it-does)
- [Usage](#usage)
- [API](#api)
- [Acknowledgements](#acknowledgements)
- [How it Works](#how-it-works)
- [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## What it Does

JfEE (['dʒæfi], **G**enerator **f**rom **E**vent**E**mitter) provides a way to turn a NodeJS EventEmitter
into an asynchronous generator, which is convenient in a lot of situations, such as when one wants to use
an EventEmitter as the data source for pipelined data processing.

## Usage

## API


## Acknowledgements

thx to https://stackoverflow.com/a/59347615/7568091

## How it Works

> Seems to be working so far.
>
> i.e. you create a dummy promise like in Khanh's solution so that you can wait for the first result, but then
> because many results might come in all at once, you push them into an array and reset the promise to wait
> for the result (or batch of results). It doesn't matter if this promise gets overwritten dozens of times
> before its ever awaited.
>
> Then we can yield all the results at once with yield* and flush the array for the next batch.





## To Do

* [ ] integrate with `intertext-splitlines`


