require('dotenv').config();
const mongoose = require('mongoose');

const Usuario   = require('../models/Usuario');
const Pais      = require('../models/Pais');
const Solicitud = require('../models/Solicitud');
const Testimonio = require('../models/Testimonio');
const Noticia   = require('../models/Noticia');

async function seed() {
  // Barrera de seguridad: el seed borra TODOS los datos.
  // En producción esto sería catastrófico, así que lo bloqueamos explícitamente.
  if (process.env.NODE_ENV === 'production') {
    console.error('❌ El seed no puede ejecutarse en producción (NODE_ENV=production).');
    process.exit(1);
  }

  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB conectado');

    // Limpiar todo antes de insertar para no tener duplicados en cada ejecución
    await Promise.all([
      Usuario.deleteMany({}),
      Pais.deleteMany({}),
      Solicitud.deleteMany({}),
      Testimonio.deleteMany({}),
      Noticia.deleteMany({}),
    ]);
    console.log('🗑️  Colecciones limpiadas');

    // ─── Países ──────────────────────────────────────────────────────────────
    const [colombia, chile, ecuador] = await Pais.create([
      { nombre: 'Colombia', codigo: 'CO', activo: true },
      { nombre: 'Chile',    codigo: 'CL', activo: true },
      { nombre: 'Ecuador',  codigo: 'EC', activo: true },
    ]);
    console.log('🌎 Países creados');

    // ─── Usuarios ─────────────────────────────────────────────────────────────
    // No llamamos bcrypt aquí: el hook pre-save del modelo ya hashea password_hash.
    // Si lo hasheamos antes también, quedaría doble-hasheado y el login nunca valdría.
    await Usuario.create([
      {
        nombre: 'Super Administrador',
        correo: 'superadmin@latamcomparte.org',
        password_hash: 'admin123',
        rol: 'superadmin',
        pais_asignado: null,
      },
      {
        nombre: 'Admin Colombia',
        correo: 'admin.co@latamcomparte.org',
        password_hash: 'admin123',
        rol: 'admin_pais',
        pais_asignado: colombia._id,
      },
      {
        nombre: 'Admin Chile',
        correo: 'admin.cl@latamcomparte.org',
        password_hash: 'admin123',
        rol: 'admin_pais',
        pais_asignado: chile._id,
      },
      {
        nombre: 'Admin Ecuador',
        correo: 'admin.ec@latamcomparte.org',
        password_hash: 'admin123',
        rol: 'admin_pais',
        pais_asignado: ecuador._id,
      },
      {
        nombre: 'Editor Colombia',
        correo: 'editor.co@latamcomparte.org',
        password_hash: 'admin123',
        rol: 'editor',
        pais_asignado: colombia._id,
      },
      // Visitante de prueba: su correo coincide con solicitudes reales del seed
      // para que el tab "Mi Solicitud" en la app tenga datos al iniciar sesión
      {
        nombre: 'Carlos Mendoza',
        correo: 'carlos@email.com',
        password_hash: 'visitante123',
        rol: 'visitante',
        pais_asignado: null,
      },
    ]);
    console.log('👥 Usuarios creados');

    // ─── Solicitudes ─────────────────────────────────────────────────────────
    await Solicitud.create([
      // Las dos primeras tienen correo del visitante de prueba
      {
        nombre: 'Carlos Mendoza',
        correo: 'carlos@email.com',
        telefono: '3001234567',
        finalidad: 'Información sobre Programa Edifica',
        pais: colombia._id,
        estado: 'gestionada',
      },
      {
        nombre: 'Carlos Mendoza',
        correo: 'carlos@email.com',
        telefono: '3001234567',
        finalidad: 'Solicitud de conferenciante para mi empresa',
        pais: colombia._id,
        estado: 'respondida',
      },
      // Resto de solicitudes de otros usuarios
      {
        nombre: 'María García',
        correo: 'maria@email.com',
        telefono: '3009876543',
        finalidad: 'Consulta sobre Programa Nodus',
        pais: colombia._id,
        estado: 'gestionada',
      },
      {
        nombre: 'Juan Torres',
        correo: 'juan@email.com',
        telefono: '3012345678',
        finalidad: 'Solicitud de conferenciante',
        pais: colombia._id,
        estado: 'respondida',
      },
      {
        nombre: 'Ana Rodríguez',
        correo: 'ana@email.com',
        telefono: '3101234567',
        finalidad: 'Información general sobre programas',
        pais: colombia._id,
        estado: 'pendiente',
      },
      {
        nombre: 'Pedro Silva',
        correo: 'pedro@gmail.com',
        telefono: '+56912345678',
        finalidad: 'Programa Edifica Chile',
        pais: chile._id,
        estado: 'pendiente',
      },
      {
        nombre: 'Valentina López',
        correo: 'val@gmail.com',
        telefono: '+56987654321',
        finalidad: 'Nodus empresarial',
        pais: chile._id,
        estado: 'pendiente',
      },
      {
        nombre: 'Roberto Paz',
        correo: 'roberto@email.ec',
        telefono: '+5939876543',
        finalidad: 'Información sobre programas Ecuador',
        pais: ecuador._id,
        estado: 'pendiente',
      },
      {
        nombre: 'Lucia Flores',
        correo: 'lucia@email.ec',
        telefono: '+5931234567',
        finalidad: 'Conferencista para evento corporativo',
        pais: ecuador._id,
        estado: 'gestionada',
      },
    ]);
    console.log('📬 Solicitudes creadas');

    // ─── Testimonios ─────────────────────────────────────────────────────────
    await Testimonio.create([
      {
        nombre: 'Andrea Castillo',
        foto_url: 'https://i.pravatar.cc/150?img=1',
        testimonio: 'Gracias al Programa Edifica pude recuperar mi negocio y hoy tengo 5 empleados. La fundación cambió mi vida completamente.',
        pais: colombia._id,
        instagram_url: 'https://instagram.com/andreacastillo',
        estado: 'publicado',
      },
      {
        nombre: 'Miguel Herrera',
        foto_url: 'https://i.pravatar.cc/150?img=2',
        testimonio: 'Nodus me enseñó a liderar con propósito. Mi empresa creció un 200% en solo 6 meses de acompañamiento.',
        pais: colombia._id,
        estado: 'publicado',
      },
      {
        nombre: 'Sandra Ruiz',
        foto_url: 'https://i.pravatar.cc/150?img=3',
        testimonio: 'Increíble experiencia con el programa. Cada módulo fue transformador y práctico.',
        pais: colombia._id,
        estado: 'borrador', // pendiente de revisión
      },
      {
        nombre: 'Felipe Morales',
        foto_url: 'https://i.pravatar.cc/150?img=4',
        testimonio: 'En Chile, Latinoamérica Comparte llegó cuando más lo necesitaba. Hoy soy un empresario exitoso con visión de futuro.',
        pais: chile._id,
        facebook_url: 'https://facebook.com/felipemorales',
        estado: 'publicado',
      },
      {
        nombre: 'Carmen Vega',
        foto_url: 'https://i.pravatar.cc/150?img=5',
        testimonio: 'El programa Edifica transformó mi perspectiva empresarial. Aprendí a gestionar mis finanzas y a crecer con propósito.',
        pais: ecuador._id,
        estado: 'publicado',
      },
      {
        nombre: 'Diego Ramírez',
        foto_url: 'https://i.pravatar.cc/150?img=6',
        testimonio: 'Gracias al acompañamiento de la fundación logré internacionalizar mi empresa. Un antes y un después en mi vida.',
        pais: chile._id,
        estado: 'publicado',
      },
    ]);
    console.log('⭐ Testimonios creados');

    // ─── Noticias ─────────────────────────────────────────────────────────────
    await Noticia.create([
      {
        titulo: 'Nueva convocatoria Edifica 2025 — Colombia',
        resumen: 'Abrimos inscripciones para la nueva cohorte del programa de emprendimiento personal.',
        contenido: 'La Fundación Latinoamérica Comparte anuncia la apertura de inscripciones para el Programa Edifica 2025 en Colombia. Este programa acompaña a emprendedores en la recuperación y fortalecimiento de sus fuentes de ingresos. Los interesados pueden inscribirse a través del formulario de contacto.',
        autor: 'Equipo Comparte Colombia',
        imagen_url: 'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=400',
        pais: colombia._id,
        estado: 'publicado',
      },
      {
        titulo: 'Programa Nodus: Líderes empresariales de 2025',
        resumen: 'Egresados del programa comparten sus logros y el impacto en sus organizaciones.',
        contenido: 'Los egresados del Programa Nodus de este año demostraron un crecimiento extraordinario. Más de 50 empresas incrementaron sus ingresos en promedio un 150%.',
        autor: 'Comunicaciones LATAM',
        imagen_url: 'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=400',
        pais: colombia._id,
        estado: 'publicado',
      },
      {
        titulo: 'Expansión del programa en Chile 2025',
        resumen: 'Nuevas ciudades se suman al programa de liderazgo en Chile.',
        contenido: 'La presencia de Latinoamérica Comparte en Chile se expande a 5 nuevas ciudades para el año 2025.',
        autor: 'Equipo Comparte Chile',
        imagen_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        pais: chile._id,
        estado: 'publicado',
      },
      {
        titulo: 'Conferencistas disponibles para eventos corporativos',
        resumen: 'Agenda disponible para el segundo semestre de 2025 en Ecuador.',
        contenido: 'La fundación pone a disposición su catálogo de conferencistas especializados en liderazgo y desarrollo personal. Contáctenos para disponibilidad y tarifas.',
        autor: 'Equipo Comparte Ecuador',
        pais: ecuador._id,
        estado: 'publicado',
      },
      {
        titulo: 'Cambios en el proceso de inscripción',
        resumen: 'Actualizamos el proceso de inscripción para una mejor experiencia.',
        contenido: 'A partir del próximo mes, el proceso de inscripción será completamente digital.',
        autor: 'Administración',
        pais: colombia._id,
        estado: 'borrador', // todavía en revisión, no publicar aún
      },
    ]);
    console.log('📰 Noticias creadas');

    // ─── Resumen ──────────────────────────────────────────────────────────────
    console.log('\n✅ SEED COMPLETADO EXITOSAMENTE');
    console.log('\n📋 CREDENCIALES DE ACCESO:');
    console.log('──────────────────────────────────────────────────────');
    console.log('ROL           CORREO                              PASS');
    console.log('──────────────────────────────────────────────────────');
    console.log('superadmin    superadmin@latamcomparte.org        admin123');
    console.log('admin_pais    admin.co@latamcomparte.org          admin123');
    console.log('admin_pais    admin.cl@latamcomparte.org          admin123');
    console.log('admin_pais    admin.ec@latamcomparte.org          admin123');
    console.log('editor        editor.co@latamcomparte.org         admin123');
    console.log('visitante     carlos@email.com                    visitante123');
    console.log('──────────────────────────────────────────────────────');
    console.log('\n💡 El visitante (carlos@email.com) tiene 2 solicitudes');
    console.log('   para probar el tab "Mi Solicitud" en la app.\n');

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ Error en seed:', err);
    process.exit(1);
  }
}

seed();
