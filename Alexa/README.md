# Climates Alexa

Using NASA's data to provide historical weather information.

## Alexa Skill

The skill currently has two intents:
- [GetTemperature](#gettemperature)
- [GetAvailableCities](#getavailablecities)

![Sample1](https://github.com/Ali-Rahimian/nasa-hackathon/raw/master/Alexa/screenshots/Sample1.png "Sample1")
![Sample2](https://github.com/Ali-Rahimian/nasa-hackathon/raw/master/Alexa/screenshots/Sample2.png "Sample2")
![Sample3](https://github.com/Ali-Rahimian/nasa-hackathon/raw/master/Alexa/screenshots/Sample3.png "Sample3")

### GetTemperature

This helps users find historical weather information. Example requests:

- How hot was Pompano Beach during summer 2017 from climates
- Average temperature in Castroville during 2018 from climates
- What is the average temperature in green cove springs during April 2018 from climates

And the Utterances used:

- How cold was [{City}](#city-intent-slot) during [{Date}](#date-intent-slot)
- How hot was [{City}](#city-intent-slot) during [{Date}](#date-intent-slot)
- Average temperature in [{City}](#city-intent-slot) in [{Date}](#date-intent-slot)
- What is the average temperature in [{City}](#city-intent-slot) in [{Date}](#date-intent-slot)

#### City Intent Slot

The name of the requested city (broader scope for demonstration purposes). Examples:

- New York
- Green Cove Springs
- Dallas

#### Date Intent Slot

The date or period for the historical data. Examples:

- Winter 2018
- 2016
- October 2017

### GetAvailableCities

This helps users find information about a few of the supported cities. Utterances:
- places for the demo
- regions for the demo
- cities for the demo
- supported cities
- what cities are available

## Prerequisites

Set up `serverless.yml`

- Update the profile name
- Update the dynamoDB arn name
- Update the Alexa Skill Id  

Set up DynamoDB

- Create a table and name it 'temperature'
- Give it a primary key of `id` (String) and `recordedTimestamp` (Number)
- Create a GSI composed of `city` (String) and `recordedTimestamp` (Number)

Ingest the data

- Make sure to add the data files in `./data/temperature` (see example)
- Run `node ./bin/etl`

### Deploying your Alexa Skill

The solution is built leveraging [Serverless](https://serverless.com/framework/docs/providers/aws/guide/). To deploy, simply run

```
sls deploy
```

This should create a lambda function with permissions to access DynamoDB as well as receive intents from Alexa.
Make sure to take note of the lambda `arn` and update your Alexa skill with it.

## Data source

The data here was sourced from NASA [Globe Visualization System](https://vis.globe.gov/GLOBE/#).
