const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Safely read Gmail credentials from functions config
let gmailEmail, gmailPassword;
try {
  gmailEmail = functions.config().gmail?.email;
  gmailPassword = functions.config().gmail?.password;

  if (!gmailEmail || !gmailPassword) {
    console.warn(
      "Gmail config not set. Run:\n" +
      'firebase functions:config:set gmail.email="yourgmail@gmail.com" gmail.password="your_app_password"'
    );
  }
} catch (e) {
  console.warn("Error reading Gmail config:", e);
}

// Nodemailer transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// Helper to send email
async function sendMail(to, subject, htmlOrText) {
  const mailOptions = {
    from: `"ANC System" <${gmailEmail}>`,
    to,
    subject,
    html: htmlOrText,
  };
  return transporter.sendMail(mailOptions);
}

// Callable function to send email manually (optional)
exports.sendAppointmentEmail = functions.https.onCall(async (data, context) => {
  try {
    const { to, subject, textOrHtml } = data;
    if (!to || !subject || !textOrHtml) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing to, subject, or textOrHtml"
      );
    }
    await sendMail(to, subject, textOrHtml);
    return { success: true };
  } catch (err) {
    console.error("sendAppointmentEmail error:", err);
    throw new functions.https.HttpsError("internal", "Email failed", { message: err.toString() });
  }
});

// Helper: lookup user email by firstname/surname (optional role)
async function lookupUserEmail(firstname, surname, role) {
  if (!firstname || !surname) return null;

  let query = admin.firestore().collection("users")
    .where("firstname", "==", firstname)
    .where("surname", "==", surname);

  if (role) query = query.where("role", "==", role);

  const snap = await query.limit(1).get();
  if (!snap.empty) {
    const d = snap.docs[0].data();
    return d.email || null;
  }
  return null;
}

// Firestore trigger: when scheduled_appointment doc is created
exports.onScheduledAppointmentCreated = functions.firestore
  .document("scheduled_appointment/{docId}")
  .onCreate(async (snap, ctx) => {
    const appointment = snap.data();
    if (!appointment) return null;

    // Determine emails (prefer doc value, fallback to lookup)
    const patientEmail = appointment.patientEmail
      ?? await lookupUserEmail(appointment.patientFirstname, appointment.patientSurname);

    const doctorEmail = appointment.doctorEmail
      ?? await lookupUserEmail(appointment.doctorFirstname, appointment.doctorSurname, "doctor");

    // Format appointment date
    let dateStr = "";
    try {
      const appt = appointment.appointment_date;
      if (appt?._seconds) {
        dateStr = new Date(appt._seconds * 1000).toLocaleString();
      } else if (typeof appt === "string") {
        dateStr = new Date(appt).toLocaleString();
      } else {
        dateStr = appointment.appointment_date?.toString() ?? "";
      }
    } catch (e) {
      dateStr = "";
    }

    // Patient email content
    const subjectPatient = `Your appointment is scheduled (${dateStr})`;
    const htmlPatient = `
      <p>Dear ${appointment.patientFirstname ?? "Patient"},</p>
      <p>Your appointment has been scheduled for <strong>${dateStr}</strong> with Dr. ${appointment.doctorFirstname ?? ""} ${appointment.doctorSurname ?? ""}.</p>
      <p>Notes: ${appointment.notes ?? "N/A"}</p>
      <p>Regards,<br/>ANC System</p>
    `;

    // Doctor email content
    const subjectDoctor = `New appointment assigned (${dateStr})`;
    const htmlDoctor = `
      <p>Dear Dr. ${appointment.doctorFirstname ?? ""} ${appointment.doctorSurname ?? ""},</p>
      <p>You have a new appointment scheduled for <strong>${dateStr}</strong> with patient ${appointment.patientFirstname ?? ""} ${appointment.patientSurname ?? ""}.</p>
      <p>Notes: ${appointment.notes ?? "N/A"}</p>
      <p>Regards,<br/>ANC System</p>
    `;

    // Send emails
    try {
      const promises = [];
      if (doctorEmail) promises.push(sendMail(doctorEmail, subjectDoctor, htmlDoctor));
      if (patientEmail) promises.push(sendMail(patientEmail, subjectPatient, htmlPatient));
      await Promise.all(promises);
      console.log("✅ Appointment emails sent:", { doctorEmail, patientEmail });
    } catch (err) {
      console.error("❌ Error sending appointment emails:", err);
    }

    return null;
  });
