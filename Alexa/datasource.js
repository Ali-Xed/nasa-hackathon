'use strict';

const config = require('./config');
const moment = require('moment');
const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient({
    region: 'us-east-1'
});

function getAverageTemperature(city, period) {
    return new Promise((resolve, reject) => {
        const { startDate, endDate, periodName } = getStartEndFromPeriod(period);

        const params = {
            TableName: config.TEMPERATURE_TABLE_NAME,
            KeyConditionExpression: '#city = :city and #recordedTimestamp between :start and :end',
            IndexName: 'city-recordedTimestamp-index',
            ExpressionAttributeNames:{
                '#city': 'city',
                '#recordedTimestamp': 'recordedTimestamp'
            },
            ExpressionAttributeValues: {
                ':city': city,
                ':start': startDate,
                ':end': endDate
            }
        };

        let results = [];
        const onScan = (err, data) => {
            if (err) {
                return reject(err);
            }
            results = results.concat(data.Items);
            if (typeof data.LastEvaluatedKey !== 'undefined') {
                params.ExclusiveStartKey = data.LastEvaluatedKey;
                ddb.query(params, onScan);
            } else {
                return resolve(new TemperatureResults(periodName, startDate, endDate, results));
            }
        };
        ddb.query(params, onScan);
    });
}

function TemperatureResults(periodName, startDate, endDate, results) {
    this.periodName = periodName;
    this.startDate = startDate;
    this.endDate = endDate;
    this.results = results;
}

TemperatureResults.prototype.averageTemperature = function () {
    if (!this.results || this.results.length === 0) {
        return null;
    }

    const avg = this.results
        .filter(t => !!t.temperature)
        .reduce((a, b) => a + parseFloat(b.temperature), 0.0) / this.results.length;

    return avg.toFixed(2);
};

function getStartEndFromPeriod(period) {
    period = (period || '').toLowerCase();

    let startDate = null;
    let endDate = null;
    let periodName = null;

    if (period.length === 0) {
        period = moment(new Date()).format('YYYY-MM-DD HH:mm')
    }

    let season = null;
    if (period.indexOf('-wi') !== -1) {
        season = 'winter';
    } else if (period.indexOf('-sp') !== -1) {
        season = 'spring';
    } else if (period.indexOf('-su') !== -1) {
        season = 'summer';
    } else if (period.indexOf('-fa') !== -1) {
        season = 'fall';
    }
    if (season !== null) {
        // YYYY-FA -> YYYY
        const year = parseInt(moment(period, 'YYYY').format('YYYY'));
        const northenHemisphere = true;
        if (northenHemisphere) {
            switch (season) {
                case 'fall': // Sep - Nov
                    startDate = moment(`${year}-September`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year}-November`, 'YYYY-MMMM').endOf('month').unix();
                    break;
                case 'winter': // Dec - Feb
                    startDate = moment(`${year}-December`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year + 1}-February`, 'YYYY-MMMM').endOf('month').unix();
                    break;
                case 'spring': // Mar - May
                    startDate = moment(`${year}-March`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year}-May`, 'YYYY-MMMM').endOf('month').unix();
                    break;
                case 'summer': // Jun - Aug
                    startDate = moment(`${year}-June`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year}-August`, 'YYYY-MMMM').endOf('month').unix();
                    break;
            }
        } else {
            switch (season) {
                case 'spring': // Sep - Nov
                    startDate = moment(`${year}-September`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year}-November`, 'YYYY-MMMM').endOf('month').unix();
                    break;
                case 'summer': // Dec - Feb
                    startDate = moment(`${year}-December`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year + 1}-February`, 'YYYY-MMMM').endOf('month').unix();
                    break;
                case 'autumn': // Mar - May
                case 'fall': // Mar - May
                    startDate = moment(`${year}-March`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year}-May`, 'YYYY-MMMM').endOf('month').unix();
                    break;
                case 'winter': // Jun - Aug
                    startDate = moment(`${year}-June`, 'YYYY-MMMM').startOf('month').unix();
                    endDate = moment(`${year}-August`, 'YYYY-MMMM').endOf('month').unix();
                    break;
            }
        }

        periodName = `${season} ${year}`;
    }

    // Year lookup
    if (periodName === null && period.length === 4) {
        startDate = moment(period, 'YYYY').startOf('year').unix();
        endDate = moment(period, 'YYYY').endOf('year').unix();
        periodName = period;
    }

    // Month lookup
    if (periodName === null) {
        const month = moment(period, 'YYYY-MM');
        startDate = month.startOf('month').unix();
        endDate = month.endOf('month').unix();
        periodName = month.format('MMMM YYYY');
    }

    return {
        startDate,
        endDate,
        periodName
    };
}

function getAvailableCities() {
    return new Promise((resolve, reject) => {
        const params = {
            TableName: config.CITY_TABLE_NAME
        };

        let results = [];
        const onScan = (err, data) => {
            if (err) {
                return reject(err);
            }
            results = results.concat(data.Items);
            if (typeof data.LastEvaluatedKey !== 'undefined') {
                params.ExclusiveStartKey = data.LastEvaluatedKey;
                ddb.scan(params, onScan);
            } else {
                return resolve(results.map(c => c.name));
            }
        };
        ddb.scan(params, onScan);
    });
}

module.exports = {
    getAverageTemperature,
    getAvailableCities
};