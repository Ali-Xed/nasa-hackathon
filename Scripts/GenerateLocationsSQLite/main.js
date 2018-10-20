'use strict'

const LocationsSQLiteGenerator = require('./LocationsSQLiteGenerator')

const inputFileUrl = process.argv[2]
const temporaryFilePath = process.argv[3]
const templateFilePath = process.argv[4]
const outputFilePath = process.argv[5]

const locationsSQLiteGenerator = new LocationsSQLiteGenerator(inputFileUrl, temporaryFilePath, templateFilePath, outputFilePath)

locationsSQLiteGenerator.run()
