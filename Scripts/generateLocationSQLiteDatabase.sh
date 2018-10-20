#  generateLocationSQLiteDatabase.sh
#  NearbyWeather
#
#  Created by Erik Maximilian Martens on 15.02.18.


LOCATIONS_SQLITE_GENERATOR_LOCATION=$PWD"/GenerateLocationsSQLite"

echo '>>>> Generating Locations SQLite Database'

cd $LOCATIONS_SQLITE_GENERATOR_LOCATION
npm install
node main.js "http://bulk.openweathermap.org/sample/city.list.json.gz" "./cityList.json" "./locationsSQLiteTemplate.sqlite" "../../NearbyWeather/locationsSQLite.sqlite"
