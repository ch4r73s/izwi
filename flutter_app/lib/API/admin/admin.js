const express = require('express');
const bodyParser = require('body-parser');
const nodemailer = require('nodemailer');
const admin = require('firebase-admin');
const app = express();

// Initialize Firebase Admin SDK
const serviceAccount = require('./path/to/your/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Uncomment if using Firestore
  // databaseURL: "https://<your-database-name>.firebaseio.com"
});

const db = admin.firestore(); // Use for Firestore
// const db = admin.database(); // Use for Realtime Database (uncomment if using Realtime Database)

app.use(bodyParser.json());

app.post('/addUser', async (req, res) => {
  const { email, name } = req.body;

  try {
    // Create a new user with Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email,
      emailVerified: false,
      password: 'temp-password', // You should generate a temporary password or handle it differently
      disabled: false,
    });

    // Store additional user information in Firestore (or Realtime Database)
    await db.collection('users').doc(userRecord.uid).set({
      email,
      name,
    });

    // Send an email to the new user with a setup link
    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: {
        user: 'your-email@gmail.com',
        pass: 'your-email-password',
      },
    });

    const mailOptions = {
      from: 'your-email@gmail.com',
      to: email,
      subject: 'Setup Your Account',
      text: `Hi ${name},\n\nPlease click the following link to set your password:\nhttp://your-app.com/register?uid=${userRecord.uid}\n\nBest,\nYour Team`,
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        return res.status(500).send('Failed to send email');
      }
      res.status(200).send('User added and email sent');
    });
  } catch (error) {
    console.error('Error adding user:', error);
    res.status(500).send('Failed to add user');
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
// // server.js

// const express = require('express');
// const bodyParser = require('body-parser');
// const nodemailer = require('nodemailer');
// const app = express();

// app.use(bodyParser.json());

// app.post('/addUser', (req, res) => {
//   const { email, name } = req.body;

//   // Here, you would add the user to your database
//   // For example:
//   // db.addUser({ email, name });

//   // Send an email to the new user with a setup link
//   const transporter = nodemailer.createTransport({
//     service: 'Gmail',
//     auth: {
//       user: 'your-email@gmail.com',
//       pass: 'your-email-password',
//     },
//   });

//   const mailOptions = {
//     from: 'your-email@gmail.com',
//     to: email,
//     subject: 'Setup Your Account',
//     text: `Hi ${name},\n\nPlease click the following link to set your password:\nhttp://your-app.com/register?email=${encodeURIComponent(email)}\n\nBest,\nYour Team`,
//   };

//   transporter.sendMail(mailOptions, (error, info) => {
//     if (error) {
//       return res.status(500).send('Failed to send email');
//     }
//     res.status(200).send('User added and email sent');
//   });
// });

// app.listen(3000, () => {
//   console.log('Server running on port 3000');
// });
