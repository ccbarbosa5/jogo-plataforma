class_name Depuracao
## Atalhos de teste (F2–F11 e R) só no modo de depuração (D-054): funcionam no editor e nos
## testes, mas não na versão publicada (exportada como release).


static func ativa() -> bool:
	return OS.is_debug_build()
