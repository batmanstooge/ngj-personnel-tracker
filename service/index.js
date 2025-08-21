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

app.use("/auth", loginRoutes);
app.use("/locations", locationRoutes);

// app.get('/verify-email', (req, res) => {
//     const token = req.query.token;
//     if (!token) {
//         return res.status(400).send(`
//       <!DOCTYPE html>
//       <html>
//       <head>
//         <title>Email Verification</title>
//         <style>
//           body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5; }
//           .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 500px; margin: 0 auto; }
//           .error { color: #d32f2f; background-color: #ffebee; padding: 15px; border-radius: 5px; margin: 20px 0; }
//           a { color: #1976d2; text-decoration: none; font-weight: bold; }
//           a:hover { text-decoration: underline; }
//         </style>
//       </head>
//       <body>
//         <div class="container">
//           <h1>Email Verification</h1>
//           <div class="error">
//             <h3>Invalid Verification Link</h3>
//             <p>No verification token provided in the link.</p>
//           </div>
//           <p>Please check your email and click the correct verification link.</p>
//         </div>
//       </body>
//       </html>
//     `);
//     }

//     // Redirect to your Flutter app with the token
//     // You'll need to replace this with your actual Flutter app URL
//     res.send(`
//     <!DOCTYPE html>
//     <html>
//     <head>
//       <title>Email Verification</title>
//       <style>
//         body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5; }
//         .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 500px; margin: 0 auto; }
//         .success { color: #388e3c; background-color: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }
//         .token { background-color: #e3f2fd; padding: 10px; border-radius: 5px; font-family: monospace; word-break: break-all; }
//         a { color: #1976d2; text-decoration: none; font-weight: bold; }
//         a:hover { text-decoration: underline; }
//         .btn { display: inline-block; background-color: #1976d2; color: white; padding: 12px 24px; border-radius: 5px; text-decoration: none; margin: 10px 0; }
//         .btn:hover { background-color: #1565c0; }
//       </style>
//     </head>
//     <body>
//       <div class="container">
//         <h1>Email Verification</h1>
//         <div class="success">
//           <h3>Verification Token Ready!</h3>
//           <p>Your verification token is:</p>
//           <div class="token">${token}</div>
//         </div>
//         <p>To complete verification:</p>
//         <ol>
//           <li>Copy the token above</li>
//           <li>Open your Location Tracker app</li>
//           <li>Enter the token in the verification screen</li>
//         </ol>
//         <p>Or if your app supports deep linking, try:</p>
//         <a href="locationtracker://verify?token=${token}" class="btn">Open App</a>
//         <p><small>If the button doesn't work, manually open the app and navigate to the verification screen.</small></p>
//       </div>
//     </body>
//     </html>
//   `);
// });


app.listen(PORT, () => {
    connectDB();
    console.log(`server is running on port ${PORT}`)
})