import 'package:chanchi_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  // Lista para seguir qué preguntas están expandidas
  final List<bool> _expandedList = [];
  // Controlador para la barra de búsqueda
  final TextEditingController _searchController = TextEditingController();
  // Lista de FAQs filtradas
  List<Map<String, String>> _filteredFaqs = [];

  // Lista completa de FAQs
  final List<Map<String, String>> _allFaqs = [
    {
      "question": "¿Cómo agrego una nueva transacción?",
      "answer": "Para agregar una nueva transacción, presiona el botón '+' en la barra de navegación inferior. Completa los detalles como tipo de transacción (ingreso o gasto), monto, categoría y fecha. Finalmente, toca 'Guardar' para registrarla."
    },
    {
      "question": "¿Cómo edito o elimino una transacción?",
      "answer": "Para editar una transacción, simplemente toca sobre ella en la lista de transacciones. Para eliminarla, puedes deslizar la transacción hacia la izquierda o usar el botón de eliminar que aparece en la pantalla de edición."
    },
    {
      "question": "¿Cómo recupero una transacción de la papelera?",
      "answer": "Accede a la papelera desde el botón en la barra superior. Allí verás todas las transacciones eliminadas. Puedes restaurarlas deslizando hacia la derecha o pulsando sobre una y seleccionando 'Restaurar'."
    },
    {
      "question": "¿Cómo creo y gestiono mis cuentas?",
      "answer": "Ve a la sección 'Cuentas' en la barra de navegación inferior. Allí puedes crear nuevas cuentas bancarias, tarjetas o efectivo, y visualizar el balance de cada una."
    },
    {
      "question": "¿Cómo cambio mi nombre de usuario?",
      "answer": "Ve a tu perfil pulsando el ícono de perfil en la esquina superior derecha, luego selecciona 'Editar perfil'. Allí podrás modificar tu nombre y guardar los cambios."
    },
    {
      "question": "¿Cómo cambio mi contraseña?",
      "answer": "En tu perfil, selecciona 'Editar perfil' y ve a la sección de contraseña. Deberás ingresar tu contraseña actual y la nueva contraseña dos veces para confirmarla."
    },
    {
      "question": "¿Qué hago si olvidé mi contraseña?",
      "answer": "En la pantalla de inicio de sesión, pulsa en '¿Olvidaste tu contraseña?' e ingresa tu correo electrónico. Recibirás un enlace para restablecer tu contraseña."
    },
    {
      "question": "¿Cómo puedo ver análisis de mis gastos?",
      "answer": "En la pantalla principal, desplázate a la pestaña 'Análisis' para ver gráficos y estadísticas sobre tus ingresos y gastos, organizados por categorías y periodos de tiempo."
    },
    {
      "question": "¿Mis datos están seguros?",
      "answer": "Sí, todos tus datos financieros están protegidos mediante cifrado y se almacenan de forma segura en nuestros servidores. Solo tú puedes acceder a ellos con tus credenciales."
    },
    {
      "question": "¿Cómo elimino mi cuenta?",
      "answer": "Para eliminar tu cuenta, ve a tu perfil, desplázate hasta el final y selecciona 'Eliminar cuenta'. Por seguridad, deberás confirmar tu contraseña para completar esta acción."
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar todas las FAQs como contraídas
    _expandedList.addAll(List.filled(_allFaqs.length, false));
    // Inicializar la lista filtrada con todas las FAQs
    _filteredFaqs = List.from(_allFaqs);
    
    // Agregar listener para la búsqueda
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para filtrar FAQs según la búsqueda
  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = List.from(_allFaqs);
      } else {
        _filteredFaqs = _allFaqs.where((faq) {
          return faq["question"]!.toLowerCase().contains(query) || 
                 faq["answer"]!.toLowerCase().contains(query);
        }).toList();
      }
      
      // Restablecer el estado de expansión
      _expandedList.clear();
      _expandedList.addAll(List.filled(_filteredFaqs.length, false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Preguntas Frecuentes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor,
              theme.colorScheme.secondary,
              isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
              isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
            ],
            stops: const [0.0, 0.2, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Título principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '¿Cómo podemos ayudarte?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar preguntas...',
                      prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Lista de FAQs
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _filteredFaqs.isEmpty
                      ? _buildNoResultsFound()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFaqs.length,
                          itemBuilder: (context, index) {
                            return _buildFaqItem(
                              context,
                              _filteredFaqs[index],
                              index,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otra búsqueda',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, 
    Map<String, String> faq, 
    int index,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedList[index];
    
    // Buscar los términos en la pregunta para resaltarlos
    final searchText = _searchController.text.toLowerCase();
    final questionText = faq["question"]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedList[index] = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 8,
        ),
        title: searchText.isEmpty
            ? Text(
                questionText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.primaryColor,
                ),
              )
            : _highlightSearchText(
                questionText, 
                searchText,
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.primaryColor,
                ),
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                  backgroundColor: Colors.yellow.shade200,
                ),
              ),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.2),
          child: Icon(
            isExpanded ? Icons.remove : Icons.add,
            color: theme.primaryColor,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 8,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16, 
              right: 16, 
              bottom: 16,
            ),
            child: searchText.isEmpty
                ? Text(
                    faq["answer"]!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  )
                : _highlightSearchText(
                    faq["answer"]!,
                    searchText,
                    TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                    TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black,
                      backgroundColor: Colors.yellow.shade200,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para resaltar el texto de búsqueda
  Widget _highlightSearchText(
    String text,
    String searchText,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    if (searchText.isEmpty) {
      return Text(text, style: normalStyle);
    }

    // Divide el texto en partes que coinciden y no coinciden con la búsqueda
    final List<TextSpan> spans = [];
    final String lowerCaseText = text.toLowerCase();
    int currentIndex = 0;

    while (true) {
      final int matchIndex = lowerCaseText.indexOf(searchText, currentIndex);
      if (matchIndex == -1) {
        // No hay más coincidencias, agregar el resto del texto
        if (currentIndex < text.length) {
          spans.add(TextSpan(
            text: text.substring(currentIndex),
            style: normalStyle,
          ));
        }
        break;
      }

      // Agregar texto antes de la coincidencia
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, matchIndex),
          style: normalStyle,
        ));
      }

      // Agregar texto resaltado
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + searchText.length),
        style: highlightStyle,
      ));

      // Actualizar índice actual
      currentIndex = matchIndex + searchText.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  // Método para abrir enlaces
  void _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}