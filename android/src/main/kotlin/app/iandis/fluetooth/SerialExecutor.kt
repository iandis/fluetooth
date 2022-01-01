package app.iandis.fluetooth

import java.util.*
import java.util.concurrent.Executor

class SerialExecutor(private val _executor: ExecutorService) : Executor {
    private val _tasks: Queue<Runnable> = ArrayDeque()
    private var _active: Runnable? = null

    @Synchronized
    override fun execute(r: Runnable) {
        _tasks.add(Runnable {
            try {
                r.run()
            } finally {
                _scheduleNext()
            }
        })
        if (_active == null) {
            _scheduleNext()
        }
    }

    @Synchronized
    private fun _scheduleNext() {
        _active = _tasks.poll()
        if (_active != null) {
            _executor.execute(_active);
        }
    }

    fun shutdown() {
        _executor.shutdown()
    }

}