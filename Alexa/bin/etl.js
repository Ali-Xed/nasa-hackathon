'use strict';

const parse = require('csv-parse');
const fs = require('fs');
const moment = require('moment');
const changeCase = require('change-case');
const nanoid = require('nanoid');
const config = require('../config');
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: 'us-east-1' });
const ddb = new AWS.DynamoDB();

const DEFAULT_BATCH_SIZE = 25;
const DATA_DIRECTORIES = [
    { name: './data/temperature', table: config.TEMPERATURE_TABLE_NAME }
];
// Err, not enough time, global variable  the city
const cities = [];

run();

function run() {
    DATA_DIRECTORIES.forEach(directory => {
        return getDirectoryFiles(directory.name)
            .then(files =>
                Promise.all(files.map(file => etlData(directory.table, file)))
                // files.reduce((p, file) => {
                //     return p.then(() => etlData(directory.table, file));
                // }, Promise.resolve())
            )
            .then(() => storeCities(cities))
            .then(() => console.log('Done!'))
            .catch(err => console.error(err));
    });
}

function getDirectoryFiles(directory) {
    return new Promise((resolve, reject) => {
        fs.readdir(directory, (err, files) => {
            return err
                ? reject(err)
                : resolve(files.map(f => [directory, f].join('\\')));
        });
    });
}

function etlData(tableName, fileName) {
    console.log('Loading ', fileName);
    return loadDataFromFile(fileName)
        .then(transformData)
        .then(data => {
            if (!data || data.length === 0) {
                return [];
            }
            const chunks = chunkArray(data, DEFAULT_BATCH_SIZE);

            return chunks.reduce((p, chunk) => {
                return p.then(() => storeData(tableName, chunk));
            }, Promise.resolve()); // initial
        });
}

function loadDataFromFile(fileName) {
    const parser = parse({});
    return new Promise((resolve, reject) => {
        const out = [];
        let headers = null;
        let record = null;

        // Use the readable stream api
        parser.on('readable', function() {
            while (record = parser.read()) {
                let newModel = {};

                if (headers === null) {
                    headers = record;
                } else {
                    headers.forEach(function(val, i) {
                        newModel[headerAlias(val)] = i < record.length
                            ? record[i]
                            : null;
                    });
                    out.push(newModel);
                }
            }
        });
        // Catch any error
        parser.on('error', function(err) {
            return reject(err);
        });
        // When we are done, test that the parsed output matched what expected
        parser.on('end', function() {
            parser.end();
            return resolve(out);
        });

        fs
            .createReadStream(fileName)
            .pipe(parser);
    })
}

function transformData(data) {
    data.forEach(c => {
        c.id = nanoid();
        if (c.date) {
            const dt = c.date.split('/').map(c => c.padStart(2, '0')).join('/');
            if (dt.split(' ')[0].length === 8) {
                c.recordedTimestamp = moment(dt, 'DD/MM/YY HH:mm:ss').unix();
                c.date = moment(dt, 'DD/MM/YY HH:mm:ss').format('DD/MM/YYYY HH:mm:ss');
            } else {
                c.recordedTimestamp = moment(dt, 'DD/MM/YYYY HH:mm:ss').unix();
                c.date = moment(dt, 'DD/MM/YYYY HH:mm:ss').format('DD/MM/YYYY HH:mm:ss');
            }
        }
    });
    return data;
}

/**
 * Returns an array with arrays of the given size.
 *
 * @param myArray {Array} Array to split
 * @param chunkSize {Integer} Size of every group
 */
function chunkArray(myArray, chunkSize) {
    const results = [];

    while (myArray.length) {
        results.push(myArray.splice(0, chunkSize));
    }

    return results;
}

function storeData(tableName, batch) {
    if (!batch || batch.length === 0) {
        return [];
    }

    return new Promise((resolve, reject) => {
        const input = batch.map(objectToDynamo);

        const params = {
            RequestItems: {
                [tableName]: input
            }
        };

        ddb.batchWriteItem(params, function(err, data) {
            if (err) {
                console.log('Error', err);
                return reject(err);
            } else {
                console.log(`Pushed ${input.length} temperature items.`);
                return resolve(data);
            }
        });
    });
}

function objectToDynamo(c) {
    let item = {};
    for (const prop in c) {
        if (c.hasOwnProperty(prop)) {
            const val = c[prop];
            if (val) {
                if (Array.isArray(val) || typeof val === 'object') {
                    item[prop] = { 'S': JSON.stringify(val) };
                } else {
                    const paramType = isNaN(val) ? 'S' : 'N';
                    item[prop] = { [paramType]: val.toString() };
                }

                if (prop === 'city' && cities.indexOf(val) === -1) {
                    cities.push(val);
                }
            }
        }
    }

    return {
        PutRequest: {
            Item: item
        }
    };
}

function storeCities(cities) {
    return new Promise((resolve, reject) => {
        const input = cities
            .map(c => {
                return {
                    id: nanoid(),
                    name: c
                }
            })
            .map(objectToDynamo);

        const params = {
            RequestItems: {
                [config.CITY_TABLE_NAME]: input
            }
        };

        ddb.batchWriteItem(params, function(err, data) {
            if (err) {
                console.log('Error', err);
                return reject(err);
            } else {
                console.log(`Pushed ${input.length} city items.`);
                return resolve(data);
            }
        });
    });
}

function headerAlias(name) {
    const retVal = changeCase.camelCase(name);
    switch (retVal) {
        case 'measuredAt':
            return 'date';
        case 'averageSurfaceTemperatureC':
        case 'temp':
        case 'currentTemp':
            return 'temperature';
        default:
            return retVal;
    }
}