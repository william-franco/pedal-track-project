# Pedal Track Backend

Backend para o projeto PedalTrack.


## Libraries

```
dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 10.0.0
dotnet add package Microsoft.EntityFrameworkCore.Design --version 10.0.0
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 10.0.0
dotnet add package Microsoft.IdentityModel.Tokens --version 8.7.0
dotnet add package System.IdentityModel.Tokens.Jwt --version 8.7.0
dotnet add package BCrypt.Net-Next --version 4.0.3
dotnet add package Scalar.AspNetCore --version 2.*
```


## Migrations

```
dotnet tool install --global dotnet-ef --version 10.*
or
dotnet tool update --global dotnet-ef --version 10.*
dotnet ef migrations add InitialCreate
dotnet ef database update
```


## Run Project

```
dotnet build
dotnet run
```


## Accessing

API: http://localhost:5000/api

OpenAPI (docs): http://localhost:5000/openapi/v1.json

Scalar UI: http://localhost:5000/scalar


## Examples of commits

```
git add . && git commit -m ":rocket: Initial commit." && git push
git add . && git commit -m ":building_construction: Added initial project architecture." && git push
git add . && git commit -m ":building_construction: Update project architecture." && git push
git add . && git commit -m ":memo: Updated project documentation." && git push
git add . && git commit -m ":memo: Updated code documentation." && git push
git add . && git commit -m ":white_check_mark: Added feature xyz." && git push
git add . && git commit -m ":wrench: Fixed xyz usage." && git push
git add . && git commit -m ":heavy_minus_sign: Removed xyz." && git push
git add . && git commit -m ":memo: Adjusted project imports." && git push
git add . && git commit -m ":arrow_up: Updated dependencies." && git push
git add . && git commit -m ":arrow_down: Removed dependencies." && git push
git add . && git commit -m ":wastebasket: Removed unused code." && git push
```


## License

[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

Copyright (c) 2026 William Franco.
