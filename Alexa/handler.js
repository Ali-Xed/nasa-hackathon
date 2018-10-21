'use strict';
const Alexa = require('ask-sdk-core');
const util = require('util');
const ds = require('./datasource');

// core functionality for fact skill
const GetWeatherHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        // checks request type
        return request.type === 'LaunchRequest'
            || (request.type === 'IntentRequest'
                && request.intent.name === 'GetTemperature');
    },
    handle(handlerInput) {
        const intent = handlerInput.requestEnvelope.request.intent;
        console.log('intent', util.inspect(intent));

        const location = intent.slots && intent.slots.City && intent.slots.City.value || 'New York';
        const date = intent.slots && intent.slots.Date && intent.slots.Date.value;

        console.log('REQUESTED', 'location', location, 'date', date);

        return ds.getAverageTemperature(location, date)
            .then(info => {
                if (!info || !info.averageTemperature()) {
                    return `Could not find information for ${location} on ${info.periodName}`;
                }

                return `The average temperature in ${location} for ${info.periodName} was ${info.averageTemperature()} degrees celsius`;
            }).then(message => {
                console.log(message);
                return handlerInput.responseBuilder
                    .speak(message)
                    .getResponse();
            });
    },
};

const GetAvailableCitiesHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        // checks request type
        return request.type === 'LaunchRequest'
            || (request.type === 'IntentRequest'
                && request.intent.name === 'GetAvailableCities');
    },
    handle(handlerInput) {
        return ds.getAvailableCities()
            .then(cities => {
                const totalCount = cities.length;
                const displayedCities = cities.splice(0, 5).join(', ');

                return handlerInput.responseBuilder
                    .speak(`We currently support ${totalCount} cities for this demo. A few examples include: ${displayedCities}`)
                    .getResponse();
            });
    }
};

const HelpHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
            && request.intent.name === 'AMAZON.HelpIntent';
    },
    handle(handlerInput) {
        return handlerInput.responseBuilder
            .speak('You can say tell me a space fact, or, you can say exit... What can I help you with?')
            .reprompt('What can I help you with?')
            .getResponse();
    },
};

const FallbackHandler = {
    // 2018-Aug-01: AMAZON.FallbackIntent is only currently available in en-* locales.
    //              This handler will not be triggered except in those locales, so it can be
    //              safely deployed for any locale.
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
            && request.intent.name === 'AMAZON.FallbackIntent';
    },
    handle(handlerInput) {
        return handlerInput.responseBuilder
            .speak('Sorry, we can\'t quite help you with that. We\'re able to provide weather related information though')
            .reprompt('What can we help you with?')
            .getResponse();
    },
};

const ExitHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
            && (request.intent.name === 'AMAZON.CancelIntent'
                || request.intent.name === 'AMAZON.StopIntent');
    },
    handle(handlerInput) {
        return handlerInput.responseBuilder
            .speak('Adios!')
            .getResponse();
    },
};

const SessionEndedRequestHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'SessionEndedRequest';
    },
    handle(handlerInput) {
        console.log(`Session ended with reason: ${handlerInput.requestEnvelope.request.reason}`);
        return handlerInput.responseBuilder.getResponse();
    },
};

const ErrorHandler = {
    canHandle() {
        return true;
    },
    handle(handlerInput, error) {
        console.log(`Error handled: ${error.message}`);
        console.log(`Error stack: ${error.stack}`);
        return handlerInput.responseBuilder
            .speak('Sorry, an error occoured')
            .reprompt('Goodbye!')
            .getResponse();
    },
};

const skillBuilder = Alexa.SkillBuilders.custom();

module.exports.handler = skillBuilder
    .addRequestHandlers(
        GetWeatherHandler,
        GetAvailableCitiesHandler,
        HelpHandler,
        ExitHandler,
        FallbackHandler,
        SessionEndedRequestHandler
    )
    // .addRequestInterceptors(LocalizationInterceptor)
    .addErrorHandlers(ErrorHandler)
    .lambda();