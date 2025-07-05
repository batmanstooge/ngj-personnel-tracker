import mongoose from "mongoose";

export const connectDB = async () => {
    try {
        const connect = await mongoose.connect(process.env.MONGO_DB_URI);
        console.debug(`mongo db connected: ${connect.connection.host}`)
    } catch (error) {
        console.debug(`Error: ${error.message}`)
        process.exit(1)
    }
}