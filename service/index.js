import express from "express";
import cors from "cors";
import bodyParser from "body-parser";

import dotenv from "dotenv";
import { connectDB } from "./config/db.js";

import loginRoutes from "./routes/auth.route.js";
import locationRoutes from "./routes/location.route.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }))

const corsOption = {
    origin: "*",
    credentials: true,
    optionSuccessStatus: 200
}

app.use(cors(corsOption));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));



app.use("/auth", loginRoutes);
app.use("/locations", locationRoutes);



app.listen(PORT, '0.0.0.0', () => {
    connectDB();
    console.log(`server is running on port ${PORT}`)
})