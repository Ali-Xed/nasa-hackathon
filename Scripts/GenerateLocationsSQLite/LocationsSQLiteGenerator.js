'use strict'

const fs = require('fs-extra')
const path = require('path')
const sqlite3 = require('sqlite3').verbose()
const StreamArray = require('stream-json/utils/StreamArray')
const zlib = require('zlib')
const request = require('request')

class LocationsSQLiteGenerator {

  constructor(inputFileUrl, temporaryFilePath, templateFilePath, outputFilePath) {
    this.inputFileUrl = inputFileUrl
    this.temporaryFilePath = temporaryFilePath
    this.templateFilePath = templateFilePath
    this.outputFilePath = outputFilePath
  }

  run() {
    this.downloadCityList(() => {
      this.extractCityList()
    })
  }

  downloadCityList(callback) {
    
    const temporaryFilePath = path.join(__dirname, this.temporaryFilePath)
    const gunzip = zlib.createGunzip()

    request.get(this.inputFileUrl, (err, res, body) => {
      const buffer = []

      request(this.inputFileUrl)
        .pipe(gunzip)
        .on('data', (data) => {
          buffer.push(data.toString())
        })
        .on('end', () => {
          const writer = fs.createWriteStream(temporaryFilePath)
          writer.write(buffer.join(''))
          writer.end(()=> {
            callback()
          })
        })
    })
  }

  extractCityList() {
    const templateFilePath = path.join(__dirname, this.templateFilePath)
    const outputFilePath = path.join(__dirname, this.outputFilePath)
    const temporaryFilePath = path.join(__dirname, this.temporaryFilePath)

    fs.copySync(templateFilePath, outputFilePath)
    
    const jsonStream = StreamArray.make()
    const db = new sqlite3.Database(outputFilePath)

    fs.createReadStream(temporaryFilePath).pipe(jsonStream.input)
    jsonStream.output.on('data', (object) => {
      db.run('INSERT INTO locations(id, name, country, latitude, longitude) VALUES ($id, $name, $country, $latitude, $longitude)', {
        $id: object.value.id,
        $name: object.value.name,
        $country: object.value.country,
        $latitude: object.value.coord.lat,
        $longitude: object.value.coord.lon
      }, (dbErr) => {
        console.log('DB Write Error:', dbErr)
      })
    })
    jsonStream.output.on('end', () => {
      console.log('Stream did end')
      fs.unlinkSync(temporaryFilePath)
    })
  }
}

module.exports = LocationsSQLiteGenerator
